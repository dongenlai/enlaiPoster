#include "win32def.h"
#include "pluto.h"
#include "rpc_mogo.h"
#include <stdlib.h>
#include <stdio.h>
#include <errno.h>
#include <sys/time.h>
#include <sys/resource.h>
#include <unistd.h>
#include <time.h>
#include <sys/stat.h>
#include <ctype.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <string.h>
#include <signal.h>
#include <fcntl.h>
#include <netdb.h>
#include <iconv.h>
#include <stdarg.h>

int g_tcp_client_fd;

unsigned int lookup_ip (const char *host)
{
    struct hostent *he;
    unsigned int ip;

    printf("lookup_ip: resolving %s\r\n", host);
    /* check for dot-quad notation.  Win95's gethostbyname() doesn't seem
    to return the ip address properly for this case like every other OS */
    ip = inet_addr (host);
    if (ip == INADDR_NONE)
    {
        he = gethostbyname (host);
        if (!he)
        {
            printf("lookup_ip: can't find ip for host %s", host);
            return 0;
        }
        memcpy (&ip, he->h_addr_list[0], he->h_length);
    }
    return ip;
}

int make_tcp_connection(const char *host, int port, unsigned int *ip)
{
    struct sockaddr_in sin;
    int     f;

    memset (&sin, 0, sizeof (sin));
    sin.sin_port = htons (port);
    sin.sin_family = AF_INET;
    if ((sin.sin_addr.s_addr = lookup_ip (host)) == 0)
        return -1;
    if (ip)
        *ip = sin.sin_addr.s_addr;
    f = socket (AF_INET, SOCK_STREAM, 0);
    if (f < 0)
    {
        return -1;
    }
    printf("make_tcp_connection: connecting to %s:%hu\r\n",inet_ntoa (sin.sin_addr), ntohs (sin.sin_port));
    if (connect(f, (struct sockaddr *) &sin, sizeof (sin)) < 0)
    {
        close (f);
        return -1;
    }

    printf("make_tcp_connection: connection established to %s\r\n", host);
    return f;
}

void usage()
{
    printf("shutdown server: program serverPort -s \r\n");
    printf("send bulletin: program serverPort -b areaId btlType btlMsg \r\n");
}

void wait_some_time()
{
    for(int i = 0; i < 2; i++)
    {
        sleep(1);
    }
}

int main(int argc,char **argv)
{
    if(argc < 3)
    {
        usage();
        return -1;
    }

    int port = atoi(argv[1]);
    if(port == 0)
    {
        printf("read server port error!!!\n");
        return -1;
    }

    unsigned int ip;
    g_tcp_client_fd = make_tcp_connection("127.0.0.1", port, &ip);
    if(g_tcp_client_fd <= 0)
    {
        printf("connect to server failed port=%d!!!\n", port);
        return -1;
    }
    if(strcmp(argv[2], "-s") == 0)
    {
        uint8_t whyShutdown = 0;
        CPluto* pu = new CPluto;
        (*pu).Encode(MSGID_ALLAPP_SHUTDOWN_SERVER) << whyShutdown << EndPluto;
        write(g_tcp_client_fd, pu->GetBuff(), pu->GetLen());

        wait_some_time();
    }
    else if(strcmp(argv[2], "-b") == 0)
    {
        if(argc < 6)
        {
            usage();
            return -1;
        }
        // areaId btlType btlMsg
        int32_t areaId = atoi(argv[3]);
        int32_t bltType = atoi(argv[4]);
        char* btlMsg = argv[5];

        CPluto* pu = new CPluto();
        (*pu).Encode(MSGID_CLIENT_BULLETIN_NOTIFY) << areaId << bltType << btlMsg << EndPluto;
        write(g_tcp_client_fd, pu->GetBuff(), pu->GetLen());

        wait_some_time();
    }
    else
    {
        usage();
    }
    close(g_tcp_client_fd);

    return 0;
}
