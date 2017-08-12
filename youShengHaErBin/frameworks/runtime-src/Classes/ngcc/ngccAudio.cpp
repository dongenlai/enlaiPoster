/**
 * Simple example of a C++ class that can be binded using the
 * automatic script generator
 */
#include <cstdlib>
#include "ngccAudio.h"
#include "cocos2d.h"
#include "zlib.h"


USING_NS_CC;

namespace ngcc{

    std::string compressDataBase64(const char* inData, size_t inLen)
    {
        z_stream c_stream;
        int err = 0;
        std::string retStr = "";

        c_stream.zalloc = (alloc_func)NULL;
        c_stream.zfree = (free_func)NULL;
        c_stream.opaque = (voidpf)NULL;
        if (deflateInit2(&c_stream, Z_DEFAULT_COMPRESSION, Z_DEFLATED, 15 + 16, 8, Z_FILTERED) != Z_OK)
            return retStr;

        size_t outLen = ((inLen + (inLen / 10) + 12) + 255);
        char* out = (char*)malloc(outLen);

        c_stream.next_in = (Bytef*)inData;
        c_stream.avail_in = (uInt)inLen;
        c_stream.next_out = (Bytef*)out;
        c_stream.avail_out = outLen;
        while (c_stream.avail_in != 0 && c_stream.total_out < outLen) 
        {
            if (deflate(&c_stream, Z_NO_FLUSH) != Z_OK)
            {
                free(out);
                return retStr;
            }
        }
        if (c_stream.avail_in != 0)
        {
            free(out);
            return retStr;
        }
        for (;;) {
            if ((err = deflate(&c_stream, Z_FINISH)) == Z_STREAM_END) 
                break;
            if (err != Z_OK)
            {
                free(out);
                return retStr;
            }
        }

        if (deflateEnd(&c_stream) != Z_OK)
        {
            free(out);
            return retStr;
        }

        char* pBase64 = NULL;
        int retLen = base64Encode((const unsigned char*)out, c_stream.total_out, &pBase64);
        if (!pBase64)
        {
            free(out);
            return retStr;
        }

        retStr.append(pBase64, retLen);

        free(pBase64);
        free(out);
        return retStr;
    }

    bool unCompressDataBase64(std::string& inStr, char** outData, size_t& outLen)
    {
        bool ret = false;
        *outData = NULL;
        outLen = 0;

        unsigned char* inPtr = NULL;
        int inLen = base64Decode((const unsigned char*)inStr.c_str(), inStr.size(), &inPtr);
        if (!inPtr)
            return ret;

        unsigned char * outPtr = NULL;
        outLen = ZipUtils::inflateMemoryWithHint(inPtr, inLen, &outPtr, 600 * 1024);
        if (!outPtr)
        {
            free(inPtr);
            return ret;
        }

        *outData = (char*)outPtr;
        free(inPtr);

        return true;
     }

    Data* fromVoid2Data(void* ptr)
    {
        return (Data*)ptr;
    }

    FMOD_RESULT F_CALLBACK callbackChannelVoice(FMOD_CHANNEL *channel, FMOD_CHANNEL_CALLBACKTYPE type, void *commanddata1, void *commanddata2)
    {
        if (FMOD_CHANNEL_CALLBACKTYPE_END == type)
        {
            FMOD::Channel *cppchannel = (FMOD::Channel *)channel;
            FMOD::Sound *curSound;
            if (FMOD_OK == cppchannel->getCurrentSound(&curSound))
            {
                curSound->setUserData((void*)1);
            }
        }
        return FMOD_OK;
    }

    void CNgcAudio::clearDataBackMusic()
    {
        if (m_pdtBackMusic)
        {
            Data* pData = fromVoid2Data(m_pdtBackMusic);
            if (!pData->isNull())
                pData->clear();

            delete pData;
            m_pdtBackMusic = NULL;
        }
        
    }

    bool CNgcAudio::releaseSound(FMOD::Sound* &pSound)
    {
        if (pSound)
        {
            if (FMOD_OK != pSound->release())
            {
                return false;
            }
            else
            {
                pSound = NULL;
            }
        }

        return true;
    }

    void CNgcAudio::writeWavHeader(FMOD::Sound *sound, int length)
    {
        int             channels, bits;
        float           rate;

        if (!sound)
        {
            return;
        }

        size_t pos = 0;

        sound->getFormat(0, 0, &channels, &bits);
        sound->getDefaults(&rate, 0, 0, 0);

        {
            TFmtChunk FmtChunk = { { { 'f', 'm', 't', ' ' }, (int)(TFmtChunk::getSize() - TRiffChunk::getSize()) }, 
                1, static_cast<unsigned short>(channels), 
                (unsigned int)rate, (unsigned int)((int)rate * channels * bits / 8), 
                (unsigned short)(1 * channels * bits / 8), (unsigned short)bits };
            TDataChunk DataChunk = { { { 'd', 'a', 't', 'a' }, length } };
            TWavHeader WavHeader = { { { 'R', 'I', 'F', 'F' }, 
                (int)(TFmtChunk::getSize() + TRiffChunk::getSize() + length) }, 
                { 'W', 'A', 'V', 'E' } };

            /*
            Write out the WAV header.
            */
            writeBufferWavHeader(pos, WavHeader);
            writeBufferFmtChunk(pos, FmtChunk);
            writeBufferRiffChunk(pos, DataChunk.chunk);
        }

        if (m_bufferLen < pos)
            m_bufferLen = pos;
    }

    unsigned int CNgcAudio::writeWavData(void* buffer, unsigned int len)
    {
        if (writeBufferBytes(m_bufferLen, buffer, len))
            return len;
        else
            return 0;
    }

    bool CNgcAudio::writeBufferBytes(size_t& pos, void* pByte, size_t len)
    {
        if (pos + len > CNgcAudio::BUFFER_MAX_LEN)
            return false;

        char* dst = m_bufferRecord + pos;
        char* src = (char*)pByte;
        for (size_t i = 0; i < len; ++i)
        {
            *(dst++) = *(src++);
            pos++;
        }


        return true;
    }

    bool CNgcAudio::writeBufferChar(size_t& pos, char ch)
    {
        if (pos + 1 > CNgcAudio::BUFFER_MAX_LEN)
            return false;

        char* dst = m_bufferRecord + pos;
        *(dst) = ch;
        pos++;

        return true;
    }

    bool CNgcAudio::writeBufferInt(size_t& pos, int data)
    {
        return writeBufferUInt(pos, (unsigned int)data);
    }

    bool CNgcAudio::writeBufferUShort(size_t& pos, unsigned short data)
    {
        if (pos + 2 > CNgcAudio::BUFFER_MAX_LEN)
            return false;

        char ch = data & 0xFF;
        writeBufferChar(pos, ch);
        ch = (data >> 8) & 0xFF;
        writeBufferChar(pos, ch);

        return true;
    }

    bool CNgcAudio::writeBufferUInt(size_t& pos, unsigned int data)
    {
        if (pos + 4 > CNgcAudio::BUFFER_MAX_LEN)
            return false;

        char ch = data & 0xFF;
        writeBufferChar(pos, ch);
        ch = (data >> 8) & 0xFF;
        writeBufferChar(pos, ch);
        ch = (data >> 16) & 0xFF;
        writeBufferChar(pos, ch);
        ch = (data >> 24) & 0xFF;
        writeBufferChar(pos, ch);

        return true;
    }

    bool CNgcAudio::writeBufferRiffChunk(size_t& pos, TRiffChunk& data)
    {
        if (pos + TRiffChunk::getSize() > CNgcAudio::BUFFER_MAX_LEN)
            return false;

        writeBufferBytes(pos, data.id, 4);
        writeBufferInt(pos, data.size);

        return true;
    }

    bool CNgcAudio::writeBufferWavHeader(size_t& pos, TWavHeader& data)
    {
        if (pos + TWavHeader::getSize() > CNgcAudio::BUFFER_MAX_LEN)
            return false;

        writeBufferRiffChunk(pos, data.chunk);
        writeBufferBytes(pos, data.rifftype, 4);

        return true;
    }

    bool CNgcAudio::writeBufferFmtChunk(size_t& pos, TFmtChunk& data)
    {
        if (pos + TFmtChunk::getSize() > CNgcAudio::BUFFER_MAX_LEN)
            return false;

        writeBufferRiffChunk(pos, data.chunk);
        writeBufferUShort(pos, data.wFormatTag);
        writeBufferUShort(pos, data.nChannels);
        writeBufferUInt(pos, data.nSamplesPerSec);
        writeBufferUInt(pos, data.nAvgBytesPerSec);
        writeBufferUShort(pos, data.nBlockAlign);
        writeBufferUShort(pos, data.wBitsPerSample);

        return true;
    }

    void CNgcAudio::checkIsRecording()
    {
        if (!m_isRecording)
            return;

        bool bRecording = false;
        if (FMOD_OK != m_pSystem->isRecording(CNgcAudio::RECORD_DEFAULT_DRIVER, &bRecording))
            return;
        if (!bRecording)
            return;

        unsigned int recordpos = 0;
        if (FMOD_OK != m_pSystem->getRecordPosition(CNgcAudio::RECORD_DEFAULT_DRIVER, &recordpos))
            return;

        if (recordpos != m_lastRecordPos)
        {
            void *ptr1, *ptr2;
            int blocklength;
            unsigned int len1, len2;
            int numchannels = 1;
            int totalWrite = 0;
            bool isAutoStop = false;

            blocklength = (int)recordpos - (int)m_lastRecordPos;
            if (blocklength < 0)
            {
                blocklength += m_recordSoundlength;
            }

            /*
            Lock the sound to get access to the raw data.
            */
            m_pSoundRecord->lock(m_lastRecordPos * numchannels * 2, blocklength * numchannels * 2, &ptr1, &ptr2, &len1, &len2);   /* * exinfo.numchannels * 2 = stereo 16bit.  1 sample = 4 bytes. */

            /*
            Write it to disk.
            */
            if (ptr1 && len1)
            {
                totalWrite += writeWavData(ptr1, len1);
                if (totalWrite == 0)
                    isAutoStop = true;
            }
            if (ptr2 && len2)
            {
                totalWrite += writeWavData(ptr2, len2);
                if (totalWrite == 0)
                    isAutoStop = true;
            }
            m_recordDatalength += totalWrite;

            /*
            Unlock the sound to allow FMOD to use it again.
            */
            m_pSoundRecord->unlock(ptr1, ptr2, len1, len2);

            if (isAutoStop)
                m_pSystem->recordStop(CNgcAudio::RECORD_DEFAULT_DRIVER);
        }

        m_lastRecordPos = recordpos;
    }

    void  CNgcAudio::checkReleaseSoundVoice()
    {
        for (int i = (int)m_vctSoundVoice.size() - 1; i >= 0; --i)
        {
            FMOD::Sound *item = m_vctSoundVoice[i];
            void* pUserData;
            if (FMOD_OK == item->getUserData(&pUserData))
            {
                if ((long)pUserData == 1)
                {
                    item->release();
                    m_vctSoundVoice.erase(m_vctSoundVoice.begin() + i);
                }
            }
        }
    }

    FMOD::Sound* CNgcAudio::findGameSound(std::string& resPath)
    {
        std::map<std::string, FMOD::Sound*>::iterator it = m_mapSoundGame.find(resPath);
        if (it != m_mapSoundGame.end())
            return it->second;
        else
            return NULL;
    }

    int CNgcAudio::cacheGameSound1(std::string& resPath)
    {
        if (!m_pSystem)
            return 100;
        if (findGameSound(resPath))
            return 2;

        Data dt = CCFileUtils::getInstance()->getDataFromFile(resPath);
        if (dt.isNull())
        {
            return 3;
        }


        FMOD_CREATESOUNDEXINFO exinfo;
        memset(&exinfo, 0, sizeof(FMOD_CREATESOUNDEXINFO));
        exinfo.cbsize = sizeof(FMOD_CREATESOUNDEXINFO);
        exinfo.length = (unsigned int)dt.getSize();
        exinfo.suggestedsoundtype = FMOD_SOUND_TYPE_OGGVORBIS;

        FMOD::Sound *pSound;
        int result = m_pSystem->createSound((const char *)dt.getBytes(), FMOD_HARDWARE | FMOD_OPENMEMORY, &exinfo, &pSound);
        dt.clear();
        if (FMOD_OK != result)
        {
            return 4;
        }

        m_mapSoundGame.insert(std::make_pair(resPath, pSound));

        return 0;
    }

    CNgcAudio::CNgcAudio() : m_pSoundBackMusic(NULL), m_pdtBackMusic(NULL), m_vctSoundVoice(), m_mapSoundGame(), m_pChannelGroupBackMusic(NULL), m_pChannelGroupVoice(NULL), m_pChannelGroupGame(NULL), m_isRecording(false),
        m_pSoundRecord(NULL), m_recordDatalength(0), m_lastRecordPos(0), m_recordSoundlength(0), m_volumeBackMusic(1.0), m_volumeVoice(1.0), m_volumeGame(1.0)
    {
        m_bufferRecord = (char*)malloc(CNgcAudio::BUFFER_MAX_LEN);
        m_bufferLen = 0;

        if (FMOD_OK != FMOD::System_Create(&m_pSystem))
        {
            m_pSystem = NULL;
            return;
        }

        unsigned int version = 0;
        if (FMOD_OK != m_pSystem->getVersion(&version))
        {
            return;
        }

        if (version < FMOD_VERSION)
        {
            return;
        }

        if (FMOD_OK != m_pSystem->init(32, FMOD_INIT_NORMAL, NULL))
        {
            return;
        }

        FMOD::ChannelGroup *masterGroup;
        if (FMOD_OK != m_pSystem->getMasterChannelGroup(&masterGroup))
        {
            return;
        }

        if (FMOD_OK != m_pSystem->createChannelGroup("ChannelGroupBackMusic", &m_pChannelGroupBackMusic))
        {
            return;
        }
        masterGroup->addGroup(m_pChannelGroupBackMusic);

        if (FMOD_OK != m_pSystem->createChannelGroup("ChannelGroupVoice", &m_pChannelGroupVoice))
        {
            return;
        }
        masterGroup->addGroup(m_pChannelGroupVoice);

        if (FMOD_OK != m_pSystem->createChannelGroup("ChannelGroupGame", &m_pChannelGroupGame))
        {
            return;
        }
        masterGroup->addGroup(m_pChannelGroupGame);
    }

    // empty destructor
    CNgcAudio::~CNgcAudio()
    {
        for (std::vector<FMOD::Sound*>::iterator it = m_vctSoundVoice.begin(); it != m_vctSoundVoice.end(); ++it)
        {
            (*it)->release();
        }
        m_vctSoundVoice.clear();
        for (std::map<std::string, FMOD::Sound*>::iterator it = m_mapSoundGame.begin(); it != m_mapSoundGame.end(); ++it)
        {
            it->second->release();
        }
        m_mapSoundGame.clear();
        releaseSound(m_pSoundBackMusic);
        releaseSound(m_pSoundRecord);

        if (m_pChannelGroupBackMusic)
            m_pChannelGroupBackMusic->release();
        if (m_pChannelGroupVoice)
            m_pChannelGroupVoice->release();
        if (m_pChannelGroupGame)
            m_pChannelGroupGame->release();

        if (m_bufferRecord)
            free(m_bufferRecord);
        clearDataBackMusic();
        if (m_pSystem)
        {
            if (FMOD_OK != m_pSystem->close())
                CCLOG("system->close failed");
            if (FMOD_OK != m_pSystem->release())
                CCLOG("system->release failed");
        }
    }

    void CNgcAudio::update()
    {
        if (m_pSystem)
        {
            m_pSystem->update();
            checkIsRecording();
            checkReleaseSoundVoice();
        }
    }

    void CNgcAudio::setPaused(int paused)
    {
        if (!m_pSystem)
            return;

        if (0 == paused)
        {
            if (m_pChannelGroupBackMusic)
                m_pChannelGroupBackMusic->setPaused(false);
            if (m_pChannelGroupVoice)
                m_pChannelGroupVoice->setPaused(false);
        }
        else
        {
            if (m_pChannelGroupBackMusic)
                m_pChannelGroupBackMusic->setPaused(true);
            if (m_pChannelGroupVoice)
                m_pChannelGroupVoice->setPaused(true);
            if (m_isRecording)
                endRecord();
        }
    }

    int CNgcAudio::playBackMusic(std::string& resPath)
    {
        if (!m_pSystem)
        {
            return 100;
        }
        if (!releaseSound(m_pSoundBackMusic))
        {
            return 1;
        }

        clearDataBackMusic();
        m_pdtBackMusic = new Data(CCFileUtils::getInstance()->getDataFromFile(resPath));
        Data* pData = fromVoid2Data(m_pdtBackMusic);
        if (pData->isNull())
        {
            return 2;
        }

        FMOD_CREATESOUNDEXINFO exinfo;
        memset(&exinfo, 0, sizeof(FMOD_CREATESOUNDEXINFO));
        exinfo.cbsize = sizeof(FMOD_CREATESOUNDEXINFO);
        exinfo.length = (unsigned int)pData->getSize();
        exinfo.suggestedsoundtype = FMOD_SOUND_TYPE_OGGVORBIS;

        // 加上FMOD_CREATESTREAM，就不用全部加载到内存了，速度快，但是只能用到1个通道。
        int result = m_pSystem->createSound((const char *)pData->getBytes(), FMOD_HARDWARE | FMOD_OPENMEMORY | FMOD_CREATESTREAM | FMOD_LOOP_NORMAL, &exinfo, &m_pSoundBackMusic);
        if (FMOD_OK != result)
        {
            clearDataBackMusic();
            return 3;
        }

        FMOD::Channel* retChannel;
        if (FMOD_OK != m_pSystem->playSound(FMOD_CHANNEL_FREE, m_pSoundBackMusic, true, &retChannel))
        {
            return 4;
        }
        else
        {
            if (m_pChannelGroupBackMusic)
            {
                retChannel->setChannelGroup(m_pChannelGroupBackMusic);
            }
            retChannel->setPaused(false);
        }

        return 0;
    }

    int CNgcAudio::playGameSound(std::string& resPath)
    {
        if (!m_pSystem)
        {
            return 100;
        }

        FMOD::Sound *pSound = findGameSound(resPath);
        if (!pSound){
            cacheGameSound1(resPath);
            pSound = findGameSound(resPath);
            if (!pSound)
                return 1;
        }

        FMOD::Channel* retChannel;
        if (FMOD_OK != m_pSystem->playSound(FMOD_CHANNEL_FREE, pSound, false, &retChannel))
        {
            return 2;
        }

        if (m_pChannelGroupGame)
        {
            retChannel->setChannelGroup(m_pChannelGroupGame);
        }

        return 0;
    }

    int CNgcAudio::setVolumeBackMusic(float volume)
    {
        if (volume < 0.0 || volume > 1.0)
            return 1;

        if (m_volumeBackMusic != volume){
            m_volumeBackMusic = volume;
            if (m_pChannelGroupBackMusic)
                m_pChannelGroupBackMusic->setVolume(m_volumeBackMusic);
        }

        return 0;
    }

    int CNgcAudio::setVolumeVoice(float volume)
    {
        if (volume < 0.0 || volume > 1.0)
            return 1;

        if (m_volumeVoice != volume){
            m_volumeVoice = volume;
            if (m_pChannelGroupVoice)
                m_pChannelGroupVoice->setVolume(m_volumeVoice);
        }

        return 0;
    }

    int CNgcAudio::setVolumeGame(float volume)
    {
        if (volume < 0.0 || volume > 1.0)
            return 1;

        if (m_volumeGame != volume){
            m_volumeGame = volume;
            if (m_pChannelGroupGame)
                m_pChannelGroupGame->setVolume(m_volumeGame);
        }

        return 0;
    }

    int CNgcAudio::mayRecord()
    {
        if (!m_pSystem || !m_bufferRecord)
            return 0;
        else
            return 1;
    }

    int CNgcAudio::isRecording()
    {
        if (m_isRecording)
            return 1;
        else
            return 0;
    }

    int CNgcAudio::startRecord()
    {
        if (!m_pSystem || !m_bufferRecord)
            return 100;
        if (m_isRecording)
            return 1;

        int numdrivers = 0;
        if (FMOD_OK != m_pSystem->getRecordNumDrivers(&numdrivers))
            return 2;
        if (numdrivers < 1)
            return 3;

        releaseSound(m_pSoundRecord);
        FMOD_CREATESOUNDEXINFO exinfo;
        memset(&exinfo, 0, sizeof(FMOD_CREATESOUNDEXINFO));

        exinfo.cbsize = sizeof(FMOD_CREATESOUNDEXINFO);
        exinfo.numchannels = 1;
        exinfo.format = FMOD_SOUND_FORMAT_PCM16;
        exinfo.defaultfrequency = 8000;
        exinfo.length = exinfo.defaultfrequency * sizeof(short) * exinfo.numchannels * 2;

        if (FMOD_OK != m_pSystem->createSound(0, FMOD_2D | FMOD_SOFTWARE | FMOD_OPENUSER, &exinfo, &m_pSoundRecord))
            return 4;

        if (FMOD_OK != m_pSoundRecord->getLength(&m_recordSoundlength, FMOD_TIMEUNIT_PCM))
            return 5;

        if (FMOD_OK != m_pSystem->recordStart(CNgcAudio::RECORD_DEFAULT_DRIVER, m_pSoundRecord, true))
            return 6;
        

        m_bufferLen = 0;
        m_recordDatalength = 0;
        m_lastRecordPos = 0;
        writeWavHeader(m_pSoundRecord, m_recordDatalength);
        m_isRecording = true;

        return 0;
    }

    std::string CNgcAudio::endRecord()
    {
        std::string retStr = "";
        if (!m_isRecording)
            return retStr;

        writeWavHeader(m_pSoundRecord, m_recordDatalength);

        bool bRecording = false;
        if (FMOD_OK != m_pSystem->isRecording(CNgcAudio::RECORD_DEFAULT_DRIVER, &bRecording))
            return retStr;
        if (bRecording)
        {
            if (FMOD_OK != m_pSystem->recordStop(CNgcAudio::RECORD_DEFAULT_DRIVER))
                return retStr;
        }

        m_isRecording = false;
        if (m_recordDatalength < 1)
        {
            retStr = "0";
            return retStr;
        }
        else
            retStr = compressDataBase64(m_bufferRecord, m_bufferLen);


        
        return retStr;
    }

    int CNgcAudio::playVoice(std::string& strVoice)
    {
        if (!m_pSystem)
            return 100;

        char* bufferSound = NULL;
        size_t bufferLen = 0;
        if (!unCompressDataBase64(strVoice, &bufferSound, bufferLen))
            return 1;

        FMOD_CREATESOUNDEXINFO exinfo;
        memset(&exinfo, 0, sizeof(FMOD_CREATESOUNDEXINFO));
        exinfo.cbsize = sizeof(FMOD_CREATESOUNDEXINFO);
        exinfo.length = (unsigned int)bufferLen;
        exinfo.suggestedsoundtype = FMOD_SOUND_TYPE_WAV;

        FMOD::Sound* pSound;
        // FMOD_NONBLOCKING playSound will failed, must use NONBLOCK callback.
        int result = m_pSystem->createSound((const char *)bufferSound, FMOD_HARDWARE | FMOD_OPENMEMORY, &exinfo, &pSound);
        if (FMOD_OK != result)
        {
            free(bufferSound);
            return 1;
        }

        FMOD::Channel* retChannel;
        if (FMOD_OK != m_pSystem->playSound(FMOD_CHANNEL_FREE, pSound, false, &retChannel))
        {
            pSound->release();
            free(bufferSound);
            return 1;
        }
        else
        {
            m_vctSoundVoice.push_back(pSound);
        }

        retChannel->setCallback(callbackChannelVoice);
        if (m_pChannelGroupVoice)
        {
            retChannel->setChannelGroup(m_pChannelGroupVoice);
        }

        free(bufferSound);

        return 0;
    }

    int CNgcAudio::cacheGameSound(std::string& resPath)
    {
        return 0;
    }

    int CNgcAudio::removeGameSound(std::string& resPath)
    {
        if (!m_pSystem)
            return 100;

        std::map<std::string, FMOD::Sound*>::iterator it = m_mapSoundGame.find(resPath);
        if (it == m_mapSoundGame.end())
            return 1;

        it->second->release();
        m_mapSoundGame.erase(it);

        return 0;
    }

    int CNgcAudio::removeBackMusic()
    {
        if (!m_pSystem)
        {
            return 100;
        }
        if (!releaseSound(m_pSoundBackMusic))
        {
            return 1;
        }

        return 0;
    }
}
