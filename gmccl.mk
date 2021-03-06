##############
# gmccl path #
##############

# Report gmccl is used and provided.
export .gmccl
.gmccl := $(abspath $(lastword $(MAKEFILE_LIST)))

#########
# debug #
#########

# $1 : the error namespace
# $2 : the error log
.error = $(error In $1 - $2)

###########
# logical #
###########

# Basic logit gical operators.
.not = $(if $1,,1)
.or = $(if $1,1,$(if $2,1,))
.and = $(if $1,$(if $2,1,),)
.xor = $(if $1,$(if $2,,1),$(if $2,1,))
.xand = $(if $1,$(if $2,1,),$(if $2,,1))

##############
# string ops #
##############

# Variable containing only one space
.gmccl.space :=
.gmccl.space +=

# Evaluates to 1 if both strings are equal, and to '' otherwise.
.seq = $(if $(subst $1,,$2)$(subst $2,,$1),,1)

##########
# checks #
##########

# If the variable $1 is not defined, an error related to $2 is thrown.
.check.def = $(if $($1),,$(error Variable $1 not defined))

# If the variable $1 is defined, an error related to $2 is thrown.
.check.ndef = $(if $($1),$(error Variable $1 not defined),)

.check.word = \
	$(if $(call .seq,$1,$(subst $(.gmccl.space),,$1)),,$(error Spaces in $1))

.check.path = \
	$(call .check.word,$1)\
	$(if $(call .seq,$(filter /%,$1),),$(error $1 is not an absolute path),)

.check.vword =\
	$(call .check.def,$1)\
	$(if\
	 	$(call .seq,$($1),$(subst $(.gmccl.space),,$($1))),\
		,\
		$(error Spaces in $1[$($1)])\
	)

.check.vpath = \
	$(call .check.vword,$1)\
	$(if\
	 	$(call .seq,$(filter /%,$($1)),),\
	 	$(error $1[$($1)] is not an absolute path),\
	 )

.check.goal = \
	$(call .check.def,MAKECMDGOALS)\
	$(if\
	 	$(call .seq,$(MAKECMDGOALS),$(subst $(.gmccl.space),,$(MAKECMDGOALS))),\
		,\
		$(error Multiple command goals ($(MAKECMDGOALS)))\
	)\
	$(if\
		$(findstring $(MAKECMDGOALS),$1),\
		,\
		$(error bad command goal ($(MAKECMDGOALS)). Options are ($1))\
	)
	
################
# n-ary checks #
################

.check.defs = $(foreach var,$1,$(call .check.def,$(var)))
.check.ndefs = $(foreach var,$1,$(call .check.ndef,$(var)))
.check.words = $(foreach var,$1,$(call .check.word,$(var)))
.check.paths = $(foreach var,$1,$(call .check.path,$(var)))
.check.vwords = $(foreach var,$1,$(call .check.vword,$(var)))
.check.vpaths = $(foreach var,$1,$(call .check.vpath,$(var)))

##############
# cross make #
##############

define .cm.inc =
include $1
endef

# recursive tree-inclusion function.
# $1 : targets dependencies variables namespace.
# $2 : current target.
# $3 : external directory.
# $4 : current inclusion history.
._cm = 	$(call .check.word,$2)\
 		$(if \
 			$(call .seq,$(findstring $2 ,$4),),\
 			,\
 			$(error cyclic dependency in cm for $2)\
 		)\
 		$(info including $3/$2.mk) $(eval -include $3/$2.mk)\
		$(foreach dep,$($1.$2), $(call $0,$1,$(dep),$3,$4 $2))

# multi-environments makefile inclusion (cross-make).
# $1 : entry environments.
# $2 : external directory.
.cm = $(call .check.word,$2)$(foreach arch,$1,$(call ._cm,_a,$(arch),$2,))

# Include the arch (_a) tree.
include $(dir $(.gmccl))arch.mk

#############
# toolchain #
#############

# Initialize toolchain variables if required.
.tc.cc ?=
.tc.ld ?=
.tc.ar ?=
.tc.oc ?=

# Export all toolchain variables.
export .tc.cc
export .tc.ld
export .tc.ar
export .tc.oc

# Check that all toolchain variables are provided.
.check.tc = $(call .check.defs,.tc.cc .tc.ld .tc.ar .tc.oc)

###########
# targets #
###########

# Initialize the environment targets if required.
.targets ?=

# Export the environment.
export .targets

# Check that the targets variables is defined.
.check.targets = $(call .check.defs,.targets)

###################
# build directory #
###################

# Initialize the build directory if required.
.bd ?=

# Export the build directory.
export .bd

# Check that all toolchain variables are provided.
.check.bd = $(call .check.vpath,.bd)

##############
# debug flag #
##############

# Initialize the debug flag if required.
.debug ?=

# Export the debug flag.
export .debug

###########################
# build environment check #
###########################

# Check the toolchain, the targets, and the build directory are valid, and all
# required variables are either defined or contain valid paths.
.check.env = \
	$(call .check.tc)\
	$(call .check.targets) $(call .check.bd) \
	$(call .check.defs,$1) $(call .check.vpaths,$2)\
	$(if $3,$(call .check.goal,$3),)

################
# Sanitization #
################

# Disable builtin implicit rules.
.SUFFIXES :
% :: %,v
% :: s.%
% :: RCS/%,v
% :: RCS/%
% :: SCCS/%
% :: SCCS/s.%


