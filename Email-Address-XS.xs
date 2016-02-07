/* Copyright (c) 2015-2016 by Pali <pali@cpan.org> */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "dovecot-parser.h"

/* Exported i_panic function for other C files */
void i_panic(const char *format, ...)
{
	va_list args;

	va_start(args, format);
	vcroak(format, &args);
	va_end(args);
}

static void append_carp_shortmess(SV *scalar)
{
	dSP;
	int count;

	ENTER;
	SAVETMPS;
	PUSHMARK(SP);

	count = call_pv("Carp::shortmess", G_SCALAR);

	SPAGAIN;

	if (count > 0)
		sv_catsv(scalar, POPs);

	PUTBACK;
	FREETMPS;
	LEAVE;
}

#define CARP_WARN false
#define CARP_DIE true
static void carp(bool fatal, const char *format, ...)
{
	va_list args;
	SV *scalar;

	va_start(args, format);
	scalar = vnewSVpvf(format, &args);
	va_end(args);

	append_carp_shortmess(scalar);

	if (!fatal)
		warn_sv(scalar);
	else
		croak_sv(scalar);

	SvREFCNT_dec(scalar);
}

static const char *get_perl_hash_value(HV *hash, const char *key)
{
	I32 klen;
	SV *scalar;
	SV **scalar_ptr;

	klen = strlen(key);

	if (!hv_exists(hash, key, klen))
		return NULL;

	scalar_ptr = hv_fetch(hash, key, klen, 0);
	if (!scalar_ptr) {
		carp(CARP_WARN, "HASH value of key '%s' is NULL", key);
		return NULL;
	}

	scalar = *scalar_ptr;

	if (!SvOK(scalar))
		return NULL;

	if (!SvPOK(scalar)) {
		carp(CARP_WARN, "HASH value of key '%s' is not string", key);
		return NULL;
	}

	return SvPV_nolen(scalar);
}

static void set_perl_hash_value(HV *hash, const char *key, const char *value)
{
	I32 klen;
	SV *scalar;

	klen = strlen(key);

	if (value)
		scalar = newSVpv(value, 0);
	else
		scalar = newSV(0);

	hv_store(hash, key, klen, scalar, 0);
}

static void message_address_add_from_perl_array(struct message_address **first_address, struct message_address **last_address, AV *array, I32 index)
{
	HV *hash;
	SV *scalar;
	SV *object;
	SV **object_ptr;
	const char *name;
	const char *mailbox;
	const char *domain;
	const char *comment;

	object_ptr = av_fetch(array, index, 0);
	if (!object_ptr) {
		carp(CARP_WARN, "Element at index %d is NULL", (int)index);
		return;
	}

	object = *object_ptr;
	if (!sv_isobject(object) || !sv_derived_from(object, "Email::Address::XS")) {
		carp(CARP_WARN, "Element at index %d is not Email::Address::XS object", (int)index);
		return;
	}

	if (!SvROK(object)) {
		carp(CARP_WARN, "Element at index %d is not reference", (int)index);
		return;
	}

	scalar = SvRV(object);
	if (SvTYPE(scalar) != SVt_PVHV) {
		carp(CARP_WARN, "Element at index %d is not HASH reference", (int)index);
		return;
	}

	hash = (HV *)scalar;

	name = get_perl_hash_value(hash, "phrase");
	mailbox = get_perl_hash_value(hash, "user");
	domain = get_perl_hash_value(hash, "host");
	comment = get_perl_hash_value(hash, "comment");

	if (!mailbox && !domain) {
		carp(CARP_WARN, "Element at index %d contains empty address", (int)index);
		return;
	}

	if (!mailbox) {
		carp(CARP_WARN, "Element at index %d contains empty user portion of address", (int)index);
		mailbox = "";
	}

	if (!domain) {
		carp(CARP_WARN, "Element at index %d contains empty host portion of address", (int)index);
		domain = "";
	}

	message_address_add(first_address, last_address, name, NULL, mailbox, domain, comment);
}

static char *get_group_name_from_perl_scalar(SV *scalar)
{
	if (!SvOK(scalar))
		return NULL;

	if (!SvPOK(scalar)) {
		carp(CARP_WARN, "Group name is not string");
		return NULL;
	}

	return SvPV_nolen(scalar);
}

static AV *get_perl_array_from_scalar(SV *scalar, const char *group_name)
{
	SV *scalar_ref;

	if (!SvOK(scalar))
		return NULL;

	if (scalar && !SvROK(scalar)) {
		carp(CARP_WARN, "Value for group '%s' is not reference", group_name);
		return NULL;
	}

	scalar_ref = SvRV(scalar);

	if (!scalar_ref || SvTYPE(scalar_ref) != SVt_PVAV) {
		carp(CARP_WARN, "Value for group '%s' is not ARRAY reference", group_name);
		return NULL;
	}

	return (AV *)scalar_ref;
}

static void message_address_add_from_perl_group(struct message_address **first_address, struct message_address **last_address, SV *scalar_group, SV *scalar_list)
{
	I32 len;
	I32 index;
	AV *array;
	const char *group_name;

	group_name = get_group_name_from_perl_scalar(scalar_group);
	array = get_perl_array_from_scalar(scalar_list, group_name);

	if (array)
		len = av_len(array) + 1;
	else
		len = 0;

	if (group_name)
		message_address_add(first_address, last_address, NULL, NULL, group_name, NULL, NULL);

	for (index = 0; index < len; ++index)
		message_address_add_from_perl_array(first_address, last_address, array, index);

	if (group_name)
		message_address_add(first_address, last_address, NULL, NULL, NULL, NULL, NULL);
}

static int count_address_groups(struct message_address *first_address)
{
	int count;
	bool in_group;
	struct message_address *address;

	count = 0;
	in_group = false;

	for (address = first_address; address; address = address->next) {
		if (!address->domain)
			in_group = !in_group;
		if (in_group)
			continue;
		++count;
	}

	return count;
}

static bool get_next_perl_address_group(struct message_address **address, SV **group_scalar, SV **addresses_scalar, HV *package)
{
	HV *hash;
	SV *object;
	SV *hash_ref;
	bool in_group;
	AV *addresses_array;

	if (!*address)
		return false;

	in_group = !(*address)->domain;

	if (in_group && (*address)->mailbox)
		*group_scalar = newSVpv((*address)->mailbox, 0);
	else
		*group_scalar = newSV(0);

	addresses_array = newAV();
	*addresses_scalar = newRV_noinc((SV *)addresses_array);

	if (in_group)
		*address = (*address)->next;

	while (*address && (*address)->domain) {
		hash = newHV();

		set_perl_hash_value(hash, "phrase", (*address)->name);
		set_perl_hash_value(hash, "user", (*address)->mailbox);
		set_perl_hash_value(hash, "host", (*address)->domain);
		set_perl_hash_value(hash, "comment", (*address)->comment);

		hash_ref = newRV_noinc((SV *)hash);
		object = sv_bless(hash_ref, package);

		av_push(addresses_array, object);

		*address = (*address)->next;
	}

	if (in_group && *address)
		*address = (*address)->next;

	return true;
}


MODULE = Email::Address::XS		PACKAGE = Email::Address::XS		

PROTOTYPES: DISABLE

SV *
format_email_groups(...)
PREINIT:
	I32 i;
	char *string;
	struct message_address *first_address;
	struct message_address *last_address;
INIT:
	if (items % 2 == 1) {
		carp(CARP_WARN, "Odd number of elements in argument list");
		XSRETURN_UNDEF;
	}
CODE:
	first_address = NULL;
	last_address = NULL;
	for (i = 0; i < items; i += 2)
		message_address_add_from_perl_group(&first_address, &last_address, ST(i), ST(i+1));
	message_address_write(&string, first_address);
	message_address_free(&first_address);
	RETVAL = newSVpv(string, 0);
	free(string);
OUTPUT:
	RETVAL

void
parse_email_groups(string, class = NO_INIT)
	char *string
	char *class
PREINIT:
	int count;
	HV *package;
	SV *group_scalar;
	SV *addresses_scalar;
	struct message_address *address;
	struct message_address *first_address;
INIT:
	if (items < 2)
		package = GvSTASH(CvGV(cv));
	else
		package = gv_stashpv(class, GV_ADD);
	if (!package)
		croak("Cannot retrieve package%s%s", (items < 2 ? "" : " for class "), (items < 2 ? "" : class));
PPCODE:
	first_address = message_address_parse(string, UINT_MAX, false);
	count = count_address_groups(first_address);
	EXTEND(SP, count * 2);
	address = first_address;
	while (get_next_perl_address_group(&address, &group_scalar, &addresses_scalar, package)) {
		PUSHs(sv_2mortal(group_scalar));
		PUSHs(sv_2mortal(addresses_scalar));
	}
	message_address_free(&first_address);

void
compose_address(OUTLIST string, mailbox, domain)
	char *string
	char *mailbox
	char *domain
CLEANUP:
	free(string);

void
split_address(string, OUTLIST mailbox, OUTLIST domain)
	char *string
	char *mailbox
	char *domain
CLEANUP:
	free(mailbox);
	free(domain);
