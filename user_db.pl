#!/usr/bin/perl -w

###
#
# Title:        user_db.pl
# Version:      v1.0 (initial version)
# Author:       Andy Howey
# Date:         06/17/2005 initial version
# Description:  This script creates a database of users with encrypted
#               passwords and privilege levels.  It is intended to be 
#               an authentication source to be used with book_db.pl
#
###
 
use strict;
use warnings;
use Digest::SHA  qw(sha256 sha256_hex sha256_base64);
use Tie::File;
use Term::ReadKey;

##################################################################
## declare all global variables to be used in this script
##################################################################

############
## Scalars
############

my $salt;
my $action;
my $fname;
my $first_init;
my $mname;
my $mid_init;
my $lname;
my $name;
my $privilege;
my $privilege_level;
my $word;
my $password;
my $loginid;
my $key;
my $user_info;

############
## Arrays
############

my @name = ();
my @secrets = ();
my @user_info = ();

############
## Hashes
############

my %name_secret = ();

##################################################################
## end of global variable declarations
##################################################################

sub KEY_INFO {
##
## create/determine search key based on the 1st two letters of the user's first and last names
##
        my @key_source = ();
        my $key_source;
	my $flname;
        my $pre_key0;
        my $pre_key1;
        print "\n\n\tPlease enter the user's first name:  ";
        chomp($fname = <STDIN>);
        print "\n\n\tPlease enter the user's last name:  ";
        chomp($lname = <STDIN>);
	$flname = join(' ',$fname,$lname);
        @key_source = split(' ',$flname);                       ## array comprised of the user's first and last names
        chomp($pre_key0 = substr($key_source[0], 0, 2));        ## get 1st two letters of the user's first name
        if ($key_source[1]) {                                   ## tests for existence of the user's last name.  If it exists,
                                                                ## get the 1st two letters, otherwise null string and warning.
                chomp($pre_key1 = substr($key_source[1], 0, 2));
        } else {
                print "\n\tThere is no 2nd element of the search key!!!\n";
                #chomp($pre_key1 = "");
        }
        if ($pre_key1) {                        ## tests for existence of 2nd element of search key.  If it
                                                ## exists, concatenates to 1st element, otherwise, search
                                                ## key consists only of 1st element
                chomp($key = $pre_key0 . $pre_key1);
        } else {
                chomp($key = $pre_key0);
        }
        return $flname;
}

sub USER_INFO {
	KEY_INFO;
        print "\n\n\tWhat is the first name of the person you want to $action?  ";
        chomp($fname = <STDIN>);
        chomp($first_init = substr($fname,0,1));
        print "\n\n\tWhat is $fname\'s middle name?  ";
        chomp($mname = <STDIN>);
        chomp($mid_init = substr($mname,0,1));
        print "\n\n\tWhat is $fname\'s last name?  ";
        chomp($lname = <STDIN>);
        #
        # now setting the privilege level for the user
        #
        print "\n\n\tWhat privilege level to you want $fname to have:";
        print "\n\n\t\tro \(Read-only -- can only look at data\)";
        print "\n\t\trw \(Read-write -- can add or update data\)";
        print "\n\t\tadmin \(Admin -- can create databases and add or update data\)";
        print "\n\n\tPlease enter selection here:  ";
        chomp($privilege = <STDIN>);
        if ("$privilege" eq "ro") {
                $privilege_level = "ro";
        } elsif ("$privilege" eq "rw") {
                $privilege_level = "rw";
        } elsif ("$privilege" eq "admin") {
                $privilege_level = "admin";
        }
        #
        # concatenates the first name, middle initial, and last name
        # of the user into a single string.
        #
        chomp(@name = ($fname,$mid_init,$lname));
        #
        # concatenates the first initial, middle initial, and last name
        # of the user into a single string and then converts the new
        # string to all lower-case characters
        #
        $loginid = $first_init . $mid_init . $lname;
        $loginid =~ tr/A-Z/a-z/;
        #
        # prompts for a "password" to be input, and then runs that string
        # through the sha256_hex interface in order to "encrypt" it
        #
        print "\n\n\tPlease enter $fname\'s new password:  ";
	ReadMode('noecho');		# don't echo
        chomp($word = <STDIN>);
	ReadMode(0);			#back to normal
        chomp($password = sha256_hex($word));
        print "\n\n\t$loginid\n\n\t$password\n\n";
	$user_info = join(":",$loginid,$fname,$mid_init,$lname,$privilege_level,$password);
}

sub ADD {
        my $response = "yes";
        while ("$response" =~ /[yY]/) {
                USER_INFO;

                # tests to determine if the record to be added already exists.  If so, prints an warning message,
                # and then asks if you want to replace the record.  If so, the existing record is deleted and the
                # "new" record is appended to the end of the database.  If not, no action is taken.
                # If the record does not exist, it is added.
                dbmopen (%name_secret,"user_db",0644) || die "can't open user_db database file";
                if ($name_secret{"@name"}) {
                        print"\n\n\"$key\" already exists in the database.  Would you like to replace the existing record (yes/no)?  ";
                        chomp(my $answer = <STDIN>);
                        if ("$answer" =~ /[yY]/) {
                                delete($name_secret{"$key"});
                                $name_secret{"$key"} = "$user_info";
                                print "\n\n\t\tThe record for \"$key\" has been replaced.\n"
                        } else {
                                print "\n\n\t\"$key\" won't be added to the database.\n\n";
                        }
                } else {
                        $name_secret{"$key"} = "$user_info";
                }
                dbmclose (%name_secret);

                print "\n\n\tDo you want to $action a record for another user (yes/no)?  ";
                chomp($response = <STDIN>);
        }
}

sub MODIFY {
        my $response = "yes";
        while ("$response" =~ /[yY]/) {
                USER_INFO;

                # tests to determine if the record being modified exists.  If not, prints an error message.
                # If so, deletes the existing record and appends the "new" record to the end of the database.
                dbmopen (%name_secret,"user_db",0644) || die "can't open user_db database file";
                if (! $name_secret{"$loginid"}) {
                        print"\n\n\"$loginid\" is not defined in the database.  Would you like to add this record (yes/no)?  ";
                        chomp(my $answer = <STDIN>);
                        if ("$answer" =~ /[yY]/) {
                                $name_secret{"$loginid"} = "@user_info";
                        } else {
                                print "\n\n\t\"$loginid\" won't be added to the database.\n\n";
                        }
                } else {
                        delete($name_secret{"$loginid"});
                        $name_secret{"$loginid"} = "@user_info";
                }
                dbmclose (%name_secret);

                print "\n\n\tDo you want to $action information for another user (yes/no)?  ";
                chomp($response = <STDIN>);
        }
}

sub VIEW {
        my $response = "yes";
        my $choice;
        my $x;
        while ("$response" =~ /[yY]/) {
                print "\n\n\tDo you want to view the record in \(C\)olumnar or \(R\)ow format:  ";
                chomp($choice = <STDIN>);
                if ("$choice" =~ /^[cC]/) {
                        KEY_INFO;
                        # tests to determine if the record to be listed exists.  If not, prints an error message.
                        # If so, displays the pertinent record.
                        dbmopen (%name_secret,"user_db",0644) || die "can't open user_db database file";
                        if (! $name_secret{"$key"}) {
                                print"\n\n\"$key\" does not exist in the database.\n\n";
                        } else {
                                ($loginid,$fname,$mname,$lname,$privilege_level,$password)=split(":",$name_secret{"$key"});
				chomp($mid_init = substr($mname,0,1));
                                print "\n\n\tLoginID\t\t\t=\t$loginid\n";
                                print "\tFirst Name\t\t=\t$fname\n";
                                print "\tMiddle Initial\t\t=\t$mid_init\n";
                                print "\tLast Name\t\t=\t$lname\n";
                                print "\tPrivilege Level\t\t=\t$privilege_level\n";
                                print "\tEncrypted Password\t=\t$password\n";
                        }
                        dbmclose (%name_secret);
                } elsif ("$choice" =~ /^[rR]/) {
                        KEY_INFO;
                        # tests to determine if the record to be listed exists.  If not, prints an error message.
                        # If so, displays the pertinent record.
                        dbmopen (%name_secret,"user_db",0644) || die "can't open user_db database file";
                        if (! $name_secret{"$key"}) {
                                print"\n\n\"$key\" does not exist in the database.\n\n";
                        } else {
                                print("\n\t\t", $key, ' = ', $name_secret{"$key"}, "\n");
                        }
                        dbmclose (%name_secret);
                } else {
                        print "\n\n\tNo valid display option chosen!!!\n";
                }
                print "\n\n\tDo you want to $action a record for another user (yes/no)?  ";
                chomp($response = <STDIN>);
        }
}

sub LIST {
        my $response = "yes";
        my $choice;
        my $x;
        my $data_file = "user_db";
        print "\n\n\tDo you want to view the record in \(C\)olumnar or \(R\)ow format:  ";
        chomp($choice = <STDIN>);
        while ("$response" =~ /[yY]/) {
                dbmopen (%name_secret,"user_db",0644) || die "can't open user_db database file";
                foreach $key (sort(keys(%name_secret))) {
                        print("\n\t", $key, ' = ', $name_secret{"$key"}, "\n");
                        # printf("\$%s{%s} = '%s'", $data_file, $key, $name_secret{$key}, "\n");
                }
                dbmclose (%name_secret);

                print "\n\n\tDo you want to $action all records in the database again (yes/no)?  ";
                chomp($response = <STDIN>);
        }
}


sub DELETE {
        my $response = "yes";
        while ("$response" =~ /[yY]/) {
                USER_INFO;

                # tests to determine if the record to be deleted exists.  If not, prints an error message.
                # If so, deletes the pertinent record.
                dbmopen (%name_secret,"user_db",0644) || die "can't open user_db database file";
                if (! $name_secret{"$key"}) {
                        print"\n\n\"$loginid\" is not defined in the database.\n\n";
                } else {
                        delete($name_secret{"$key"});
                        print"\n\t\t\"$loginid\" has been deleted from the database.\n\n";
                }
                dbmclose (%name_secret);

                print "\n\n\tDo you want to $action information for another user (yes/no)?  ";
                chomp($response = <STDIN>);
        }
}

##
## This is the main routine of the script
##

my $reply = "";
until ("$reply" =~ /^[qQ]uit/) {
        print "\n\n\tPlease choose one of the options below:";
        print "\n\n\t\t\(A\/a\)dd a new user";
        print "\n\t\t\(M\/m\)odify an existing user";
        print "\n\t\t\(V\/v\)iew a user";
        print "\n\t\t\(L/\l\)ist all records";
        print "\n\t\t\(D\/d\)elete a user";
        print "\n\t\t\(Q\/q\)uit";
        print "\n\n\tPlease enter your choice here:  ";
        chomp(my $reply = <STDIN>);
        if ("$reply" =~ /^[aA]/) {
                $action = "add";
                ADD;
        } elsif ("$reply" =~ /^[mM]/) {
                $action = "modify";
                MODIFY;
        } elsif ("$reply" =~ /^[vV]/) {
                $action = "view";
                VIEW;
        } elsif ("$reply" =~ /^[lL]/) {
                $action = "list";
                LIST;
        } elsif ("$reply" =~ /^[dD]/) {
                $action = "delete";
                DELETE;
        } elsif ("$reply" =~ /^[qQ]/) {
                print "\n\n\t\tGoodbye...\n\n";
                exit;
        } else {
                print "\n\n\tNo appropriate action selected.  Please select a correct option.\n\n";
        }
}

