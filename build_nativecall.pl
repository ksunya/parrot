#! perl -w
#
# Build up the native call routines.

my %ret_count;
%ret_count = (p => [0,0,0,1,0],        # Returning a pointer that we PMC stuff
	      i => [0,1,0,0,0],        # Returning an int
	      3 => [0,1,0,0,0],        # Returning an int pointer
	      l => [0,1,0,0,0],        # Returning a long
	      c => [0,1,0,0,0],        # returning a char
	      s => [0,1,0,0,0],        # returning a short
	      f => [0,0,0,0,1],        # returning a float
	      d => [0,0,0,0,1],        # returning a double
	      t => [0,0,1,0,0],        # returning a string
	      v => [0,0,0,0,0],        # void return
#	      b => [0,0,1,0,0],        # Returns a buffer
#	      B => [0,0,1,0,0],        # Returns a buffer
	     );


my (%ret_type) = (p => "void *",
		  i => "int",
		  3 => "int *",
		  l => "long",
		  4 => "long *",
		  c => "char",
		  s => "short",
                  2 => "short *",
                  f => "float",
                  d => "double",
                  t => "char *",
		  v => "void",
#		  b => "void *",
#		  B => "void **",
                 );

my (%proto_type) = (p => "void *",
		    i => "int",
		    3 => "int *",
		    l => "long",
		    4 => "long *",
		    c => "char",
		    s => "short",
                    2 => "short *",
		    f => "float",
		    d => "double",
		    t => "char *",
		    v => "void",
		    I => "struct Parrot_Interp *",
		    P => "PMC *",
#		    b => "void *",
		    B => "void **",
		   );

my (%other_decl) = (p => "PMC *final_destination = pmc_new(interpreter, enum_class_UnManagedStruct);",
#		    b => "Buffer *final_destination = new_buffer_header(interpreter);\nPObj_external_SET(final_destination)",
#		    B => "Buffer *final_destination = new_buffer_header(interpreter);\nPObj_external_SET(final_destination)",
		   );

my (%ret_type_decl) = (p => "void *",
		       i => "int",
		       3 => "int *",
		       l => "long",
		       4 => "long *",
		       c => "char",
		       s => "short",
                       2 => "short *",
                       f => "float",
                       d => "double",
                       t => "char *",
		       v => "void *",
#		       b => "void *",
#		       B => "void **",
                     );

my (%ret_assign) = (p => "PMC_data(final_destination) = return_data;\nPMC_REG(5) = final_destination;",
		    i => "INT_REG(5) = return_data;",
		    3 => "INT_REG(5) = *return_data;",
		    l => "INT_REG(5) = return_data;",
		    4 => "INT_REG(5) = *return_data;",
		    c => "INT_REG(5) = return_data;",
		    s => "INT_REG(5) = return_data;",
                    2 => "INT_REG(5) = *return_data;",
                    f => "NUM_REG(5) = return_data;",
                    d => "NUM_REG(5) = return_data;",
		    v => "",
#		    b => "final_destination->bufstart = return_data;\nSTR_REG(5) = final_destination",
#		    B => "final_destination->bufstart = *return_data;\nSTR_REG(5) = final_destination",
                   );

my (%func_call_assign) = (p => "return_data = ",
			  i => "return_data = ",
			  3 => "return_data = ",
			  2 => "return_data = ",
			  4 => "return_data = ",
			  l => "return_data = ",
			  c => "return_data = ",
			  s => "return_data = ",
                          f => "return_data = ",
                          d => "return_data = ",
			  b => "return_data = ",
#			  B => "return_data = ",
#		          v => "",
                          );

open NCI, ">nci.c" or die "Can't open nci.c!";

print NCI <<'HEAD';
/*
 * !!!!!!!   DO NOT EDIT THIS FILE   !!!!!!!
 *
 * This file is generated automatically by build_nativecall.pl.
 *
 * Any changes made here will be lost!
 *
 */

/* nci.c
 *  Copyright: 2001-2003 The Perl Foundation.  All Rights Reserved.
 *  CVS Info
 *     $Id$
 *  Overview:
 *     Native Call Interface routines. The code needed to build a
 *     parrot to C call frame is in here
 *  Data Structure and Algorithms:
 *  History:
 *  Notes:
 *  References:
 */

#include "parrot/parrot.h"

#if !defined(INT_REG)
#  define INT_REG(x) interpreter->int_reg.registers[x]
#endif
#if !defined(NUM_REG)
#  define NUM_REG(x) interpreter->num_reg.registers[x]
#endif
#if !defined(STR_REG)
#  define STR_REG(x) interpreter->string_reg.registers[x]
#endif
#if !defined(PMC_REG)
#  define PMC_REG(x) interpreter->pmc_reg.registers[x]
#endif

#if defined(HAS_JIT) && defined(I386)
#  include "parrot/exec.h"
#  include "parrot/jit.h"
#  define CAN_BUILD_CALL_FRAMES
#endif

#if !defined(CAN_BUILD_CALL_FRAMES)
/* All our static functions that call in various ways. Yes, terribly
   hackish, but that's just fine */

static void
set_return_val(struct Parrot_Interp *interpreter, int stack, int ints,
               int strings, int pmcs, int nums) {
    INT_REG(0) = stack;
    INT_REG(1) = ints;
    INT_REG(2) = strings;
    INT_REG(3) = pmcs;
    INT_REG(4) = nums;
}

HEAD

# '
while (<>) {
    s/#.*$//;
    s/^\s*//;
    s/\s*$//;
    next unless $_;
    my ($ret, $args) = split /\s/, $_;
    my @arg;
    my %reg_count;
    @reg_count{qw(p i s n)} = (5, 5, 5, 5);
    if (defined $args and not $args =~ m/^\s*$/ ) {
    foreach (split //, $args) {
	push @arg, make_arg($_, \%reg_count);
    }
    }

    # Header
    generate_func_header($ret, $args, (join ",", @arg), $ret_type{$ret},
			 $ret_type_decl{$ret}, $func_call_assign{$ret},
			 $other_decl{$ret},  $ret_assign{$ret});

    # Body

    # Footer
    set_return_count(@{$ret_count{$ret}});
}

$icky_global_bit = join("\n", @icky_global_variable);

print NCI <<TAIL;
#endif

/* This function serves a single purpose. It takes the function
   signature for a C function we want to call and returns a pointer
   to a function that can call it. */
void *
build_call_func(struct Parrot_Interp *interpreter, PMC *pmc_nci,
                String *signature)
{
#if defined(CAN_BUILD_CALL_FRAMES)
    /* This would be a good place to put the code that builds the
       frames. Undoubtedly painfully platform-dependent */

     return Parrot_jit_build_call_func(interpreter, pmc_nci, signature);

#else
    /* And in here is the platform-independent way. Which is to say
       "here there be hacks" */
    UNUSED(pmc_nci);
    if (0 == string_length(signature)) return F2DPTR(pcf_v_v);
    $icky_global_bit
    PANIC("Unknown signature type");
    return NULL;
#endif
}

TAIL

close NCI;


sub make_arg {
    my ($argtype, $reg_ref) = @_;
    /p/ && do {my $regnum = $reg_ref->{p}++;
	       return "PMC_data(PMC_REG($regnum))";
              };
    /i/ && do {my $regnum = $reg_ref->{i}++;
	       return "(int)INT_REG($regnum)";
              };
    /3/ && do {my $regnum = $reg_ref->{i}++;
	       return "(int*)&INT_REG($regnum)";
              };
    /l/ && do {my $regnum = $reg_ref->{i}++;
	       return "(long)INT_REG($regnum)";
              };
    /4/ && do {my $regnum = $reg_ref->{i}++;
	       return "(long*)&INT_REG($regnum)";
              };
    /s/ && do {my $regnum = $reg_ref->{i}++;
	       return "(short)INT_REG($regnum)";
              };
    /2/ && do {my $regnum = $reg_ref->{i}++;
	       return "(short*)&INT_REG($regnum)";
              };
    /f/ && do {my $regnum = $reg_ref->{n}++;
	       return "(float)NUM_REG($regnum)";
              };
    /d/ && do {my $regnum = $reg_ref->{n}++;
	       return "(double)NUM_REG($regnum)";
              };
    /t/ && do {my $regnum = $reg_ref->{s}++;
	       return "string_to_cstring(interpreter, STR_REG($regnum))";
              };
    /b/ && do {my $regnum = $reg_ref->{s}++;
	       return "STR_REG($regnum)->bufstart";
              };
    /B/ && do {my $regnum = $reg_ref->{s}++;
	       return "&(STR_REG($regnum)->bufstart)";
              };
    /I/ && do {
	       return "interpreter";
              };
    /P/ && do {my $regnum = $reg_ref->{p}++;
               return "PMC_REG($regnum)";
              };

}

sub set_return_count {
    my ($stack, $int, $string, $pmc, $num) = @_;
    print NCI <<FOOTER;
    set_return_val(interpreter, $stack, $int, $string, $pmc, $num);
    return;
}


FOOTER
}

sub generate_func_header {
    my ($return, $params, $call_params, $ret_type, $ret_type_decl,
	$return_assign, $other_decl, $final_assign) = @_;
    $other_decl ||= "";

    if (defined $params) {
    my $proto = join ', ', map { $proto_type{$_} } split '', $params;
    print NCI <<HEADER;
static void
pcf_${return}_$params(struct Parrot_Interp *interpreter, PMC *self)
{
    typedef $ret_type (*func_t)($proto);
    func_t pointer;
    $ret_type_decl return_data;
    $other_decl

    pointer =  (func_t)D2FPTR(self->cache.struct_val);
    $return_assign ($ret_type)(*pointer)($call_params);
    $final_assign
HEADER
  }
  else {
    print NCI <<HEADER;
static void
pcf_${return}(struct Parrot_Interp *interpreter, PMC *self)
{
    $ret_type (*pointer)(void);
    $ret_type_decl return_data;
    $other_decl

    pointer =  ($ret_type (*)(void))D2FPTR(self->cache.struct_val);
    $return_assign ($ret_type)(*pointer)();
    $final_assign
HEADER
  }

  if (defined $params) {
  push @icky_global_variable, <<CALL;
    if (!string_compare(interpreter, signature,
      string_from_cstring(interpreter, "$return$params", 0)))
          return F2DPTR(pcf_${return}_$params);
CALL
  }
  else {
  push @icky_global_variable, <<CALL;
    if (!string_compare(interpreter, signature,
      string_from_cstring(interpreter, "$return", 0)))
          return F2DPTR(pcf_${return});
CALL
  }

}


=for comment
This is the template thing

static void pcf_$funcname(struct Parrot_Interp *interpreter, PMC *self) {
    $ret_type (*pointer)();
    $ret_type return_data;

    pointer = self->cache.struct_val;
    return_data = ($ret_type)(*pointer)($params);
    $ret_reg  = return_data;
    INT_REG(0) = $stack_returns;
    INT_REG(1) = $int_returns;
    INT_REG(2) = $string_returns;
    INT_REG(3) = $pmc_returns;
    INT_REG(4) = $num_returns;
    return;
}
EOR

}
=end comment
