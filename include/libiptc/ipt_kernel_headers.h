/* This is the userspace/kernel interface for Generic IP Chains,
   required for libc6. */
#ifndef _FWCHAINS_KERNEL_HEADERS_H
#define _FWCHAINS_KERNEL_HEADERS_H

#if defined(__GLIBC__) && __GLIBC__ == 2
#include <netinet/ip.h>
#include <netinet/ip_icmp.h>
#include <netinet/tcp.h>
#include <netinet/udp.h>
#include <net/if.h>
#include <sys/types.h>
#include <limits.h>
#else /* libc5 */
#include <sys/socket.h>
#include <linux/ip.h>
#include <linux/in.h>
#include <linux/if.h>
#include <linux/icmp.h>
#include <linux/tcp.h>
#include <linux/udp.h>
#include <linux/types.h>
#endif
#endif