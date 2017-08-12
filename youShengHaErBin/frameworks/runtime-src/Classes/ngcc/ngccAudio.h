#ifndef __SIMPLE_CLASS_H__
#define __SIMPLE_CLASS_H__

#include <string>
#include <vector>
#include <map>
#include <stdint.h>
#include "ngcc/inc/fmod.hpp"


namespace ngcc {
    class CNgcAudio
    {
    private:
        struct TRiffChunk
        {
            signed char id[4];
            int 		size;

            static size_t getSize()
            {
                return 4 + 4;
            }
        };
        struct TFmtChunk
        {
            TRiffChunk      chunk;
            unsigned short	wFormatTag;    /* format type  */
            unsigned short	nChannels;    /* number of channels (i.e. mono, stereo...)  */
            unsigned int	nSamplesPerSec;    /* sample rate  */
            unsigned int	nAvgBytesPerSec;    /* for buffer estimation  */
            unsigned short	nBlockAlign;    /* block size of data  */
            unsigned short	wBitsPerSample;    /* number of bits per sample of mono data */

            static size_t getSize()
            {
                return TRiffChunk::getSize() + 4 + 8 + 4;
            }
        };
        struct TDataChunk
        {
            TRiffChunk   chunk;

            static size_t getSize()
            {
                return TRiffChunk::getSize();
            }
        };
        struct TWavHeader
        {
            TRiffChunk   chunk;
            signed char rifftype[4];

            static size_t getSize()
            {
                return TRiffChunk::getSize() + 4;
            }
        };

        FMOD::System        *m_pSystem;
        void                *m_pdtBackMusic;                // 这样jsb生成的时候，不用安装cocosFrameWork
        FMOD::Sound         *m_pSoundBackMusic;
        std::vector<FMOD::Sound*> m_vctSoundVoice;
        std::map<std::string, FMOD::Sound*> m_mapSoundGame;
        FMOD::ChannelGroup  *m_pChannelGroupBackMusic;
        FMOD::ChannelGroup  *m_pChannelGroupVoice;
        FMOD::ChannelGroup  *m_pChannelGroupGame;
        static const size_t BUFFER_MAX_LEN = 600 * 1024;
        static const int    RECORD_DEFAULT_DRIVER = 0;
        char                *m_bufferRecord;
        size_t              m_bufferLen;
        bool                m_isRecording;
        FMOD::Sound         *m_pSoundRecord;
        unsigned int        m_recordDatalength;
        unsigned int        m_lastRecordPos;
        unsigned int        m_recordSoundlength;
        float               m_volumeBackMusic;
        float               m_volumeVoice;
        float               m_volumeGame;

        void clearDataBackMusic();
        bool releaseSound(FMOD::Sound* &pSound);
        void writeWavHeader(FMOD::Sound *sound, int length);
        unsigned int writeWavData(void* buffer, unsigned int len);
        bool writeBufferBytes(size_t& pos, void* pByte, size_t len);
        bool writeBufferChar(size_t& pos, char ch);
        bool writeBufferInt(size_t& pos, int data);
        bool writeBufferUShort(size_t& pos, unsigned short data);
        bool writeBufferUInt(size_t& pos, unsigned int data);
        bool writeBufferRiffChunk(size_t& pos, TRiffChunk& data);
        bool writeBufferWavHeader(size_t& pos, TWavHeader& data);
        bool writeBufferFmtChunk(size_t& pos, TFmtChunk& data);
        void checkIsRecording();
        void checkReleaseSoundVoice();
        FMOD::Sound* findGameSound(std::string& resPath);
        int cacheGameSound1(std::string& resPath);
    public:
        CNgcAudio();
        ~CNgcAudio();

        void update();
        void setPaused(int paused);
        int playBackMusic(std::string& resPath);
        int playGameSound(std::string& resPath);
        int setVolumeBackMusic(float volume);
        int setVolumeVoice(float volume);
        int setVolumeGame(float volume);
        int mayRecord();
        int isRecording();
        int startRecord();
        std::string endRecord();
        int playVoice(std::string& strVoice);
        int cacheGameSound(std::string& resPath);
        int removeGameSound(std::string& resPath);
        int removeBackMusic();
    };
};


#endif
