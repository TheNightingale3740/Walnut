#include "Walnut/Networking/NetworkingUtils.h"

#include "Walnut/Utils/StringUtils.h"

#include <netdb.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <arpa/inet.h>

#include <vector>

namespace Walnut::Utils {

	std::string ResolveDomainName(std::string_view name)
	{
		// Adapted from the WinSock implementation in Platform/Windows, using the
		// portable getaddrinfo API rather than WSA-prefixed calls.
		// TODO(Yan): better error logging

		bool hasPort = name.find(":") != std::string::npos;
		std::string domain, port;
		if (hasPort)
		{
			std::vector<std::string> domainAndPort = SplitString(name, ':');
			if (domainAndPort.size() != 2)
				return {};
			domain = domainAndPort[0];
			port = domainAndPort[1];
			name = domain;
		}

		addrinfo hints;
		memset(&hints, 0, sizeof(hints));
		hints.ai_family = AF_UNSPEC;
		hints.ai_socktype = SOCK_STREAM;
		hints.ai_protocol = IPPROTO_TCP;

		addrinfo* addressResult = NULL;
		int result = getaddrinfo(name.data(), nullptr, &hints, &addressResult);
		if (result != 0)
		{
			printf("getaddrinfo failed with error: %d\n", result);
			return {};
		}

		std::string ipAddressStr;
		for (addrinfo* ptr = addressResult; ptr != NULL; ptr = ptr->ai_next)
		{
			switch (ptr->ai_family)
			{
			case AF_UNSPEC:
				// Unspecified
				break;
			case AF_INET:
			{
				sockaddr_in* sockaddr_ipv4 = (sockaddr_in*)ptr->ai_addr;
				char ipAddress[INET_ADDRSTRLEN];
				if (inet_ntop(AF_INET, &sockaddr_ipv4->sin_addr, ipAddress, sizeof(ipAddress)))
					ipAddressStr = ipAddress;
				break;
			}
			case AF_INET6:
			{
				const socklen_t ipbufferlength = 46;
				char ipstringbuffer[ipbufferlength];
				socklen_t actualIPBufferLength = ipbufferlength;
				if (getnameinfo(ptr->ai_addr, ptr->ai_addrlen, ipstringbuffer,
					actualIPBufferLength, nullptr, 0, NI_NUMERICHOST) == 0)
				{
					ipAddressStr = std::string(ipstringbuffer, actualIPBufferLength);
				}
				break;
			}
			}
		}

		freeaddrinfo(addressResult);

		return hasPort ? (ipAddressStr + ":" + port) : ipAddressStr;
	}

}