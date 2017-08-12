#ifndef __SIMPLE_CLASS_H__
#define __SIMPLE_CLASS_H__

#include <string>
#include <stdint.h>

enum EAsyncStatus {
	easLoading = 1,
	easLoadSuccess,
	easLoadErrror
};

namespace ngcc {
    class CSyncPubUtils
    {
    protected:
        int m_someField;
        int m_someOtherField;
        char* m_anotherMoreComplexField;

    public:
        static const uint32_t OBJECT_TYPE = 0x777;
        virtual uint32_t getObjectType() {
            return CSyncPubUtils::OBJECT_TYPE;
        };

        CSyncPubUtils();
        CSyncPubUtils(int m) : m_someField(m) {};
        CSyncPubUtils(int m1, int m2) : m_someField(m1), m_someOtherField(m2) {};
        ~CSyncPubUtils();

        // these methods are simple, can be defined inline
        int getSomeField() {
            return m_someField;
        }
        int getSomeOtherField() {
            return m_someOtherField;
        }
        const char *getAnotherMoreComplexField() {
            return m_anotherMoreComplexField;
        }
        void setSomeField(int f) {
            m_someField = f;
        }
        void setSomeField() {

        }
        void setSomeOtherField(int f) {
            m_someOtherField = f;
        }
        void setAnotherMoreComplexField(const char *str);

        long long thisReturnsALongLong();

        static void func();
        static void func(int a);
        static void func(int a, float b);

        long long receivesLongLong(long long someId);
        std::string returnsAString();
        const char *returnsACString();

        int doSomeProcessing(std::string arg1, std::string arg2);
    };

    class CAsyncPubUtils
    {
    private:
        int m_status;
    public:
        CAsyncPubUtils();
        ~CAsyncPubUtils();

        int getStatus()
        {
            return m_status;
        }
    };
};

namespace SomeNamespace {
class AnotherClass {
protected:
	int justOneField;

public:
    static const uint32_t OBJECT_TYPE = 0x778;
    virtual uint32_t getObjectType() {
        return AnotherClass::OBJECT_TYPE;
    };
	int aPublicField;

	AnotherClass();
	~AnotherClass();

	// also simple methods, can be defined inline
	int getJustOneField() {
		return justOneField;
	}
	// wrong setter - won't work (needs ONLY one parameter in order to work)
	void setJustOneField() {
		justOneField = 999;
	}

	void doSomethingSimple();
};
};

#endif
