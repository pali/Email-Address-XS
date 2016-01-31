#ifndef DOVECOT_PARSER_H
#define DOVECOT_PARSER_H

#include <stdbool.h>

/* group: ... ; will be stored like:
   {name = NULL, NULL, "group", NULL}, ..., {NULL, NULL, NULL, NULL}
*/
struct message_address {
	struct message_address *next;

	/* display-name */
	char *name;
	/* route string contains the @ prefix */
	char *route;
	/* local-part */
	char *mailbox;
	char *domain;
	/* there were errors when parsing this address */
	bool invalid_syntax;
};

/* Parse message addresses from given data. If fill_missing is TRUE, missing
   mailbox and domain are set to MISSING_MAILBOX and MISSING_DOMAIN strings.
   Otherwise they're set to "".

   Note that giving an empty string will return NULL since there are no
   addresses. */
struct message_address *
message_address_parse(const char *str, unsigned int max_addresses, bool fill_missing);

void message_address_add(struct message_address **first, struct message_address **last,
			 const char *name, const char *route, const char *mailbox, const char *domain);

void message_address_free(struct message_address **addr);

void message_address_write(char **str, const struct message_address *addr);

#endif
