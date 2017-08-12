/**
 * Simple example of a C++ class that can be binded using the
 * automatic script generator
 */
#include <cstdlib>
#include "cocos2d.h"
#include "ngccPubUtils.h"

USING_NS_CC;

namespace ngcc{

    CSyncPubUtils::CSyncPubUtils()
    {
        // just set some fields
        m_someField = 0;
        m_someOtherField = 10;
        m_anotherMoreComplexField = NULL;

        CCLOG("CreateCSyncPubUtils this=%ld", long(this));
    }

    // empty destructor
    CSyncPubUtils::~CSyncPubUtils()
    {
        CCLOG("DestroyCSyncPubUtils this=%ld", long(this));
    }

    long long CSyncPubUtils::thisReturnsALongLong() {
        static long long __id = 0;
        return __id++;
    }

    void CSyncPubUtils::func() {
    }

    void CSyncPubUtils::func(int a) {
    }

    void CSyncPubUtils::func(int a, float b) {
    }

    long long CSyncPubUtils::receivesLongLong(long long someId) {
        return someId + 1;
    }

    std::string CSyncPubUtils::returnsAString() {
        std::string myString = "my std::string";
        return myString;
    }

    const char *CSyncPubUtils::returnsACString() {
        return "this is a c-string";
    }

    // just a very simple function :)
    int CSyncPubUtils::doSomeProcessing(std::string arg1, std::string arg2)
    {
        return arg1.length() + arg2.length();
    }

    void CSyncPubUtils::setAnotherMoreComplexField(const char *str)
    {
        if (m_anotherMoreComplexField) {
            free(m_anotherMoreComplexField);
        }
        size_t len = strlen(str);
        m_anotherMoreComplexField = (char *)malloc(len);
        memcpy(m_anotherMoreComplexField, str, len);
    }

    CAsyncPubUtils::CAsyncPubUtils() : m_status(easLoading)
    {

    }

    CAsyncPubUtils::~CAsyncPubUtils()
    {

    }
}

namespace SomeNamespace
{
AnotherClass::AnotherClass()
{
	justOneField = 1313;
	aPublicField = 1337;
}
// empty destructor
AnotherClass::~AnotherClass()
{
}

void AnotherClass::doSomethingSimple() {
	fprintf(stderr, "just doing something simple\n");
}
};
