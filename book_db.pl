#!/usr/bin/perl -T

###
#
# Title:        book_db.pl
# Version:      v1.0 (initial version)
# Author:       Andy Howey
# Date:         06/17/2005 initial version
# Description:  This script creates a database of book with relevant
#               information about each book.  It uses BerkeleyDB as
#               its database engine.
#
###

use warnings;
use strict;
use POSIX;

##################################################################
## Modified 09/11/2015 to add variables and logic for
## Purchase Price and Purchase Currency
##################################################################

##################################################################
## declare all global variables to be used in this script
##################################################################

############
## Scalars
############

my $action;
my $name;
my $authors;
my $title;
my $isbn;
my $category;
my $subcategory;
my $pubyear;
my $publisher;
my $edition;
my $price;
my $key;
my $book_info;
my $book_list;

############
## Arrays
############

my @name = ();

############
## Hashes
############

my %book_list = ();

##################################################################
## end of global variable declarations
##################################################################

sub AUTHOR_INFO {
        my $answer;
        my $countword;
        $authors = "";
        print "\n\n\tDoes this book have more than one author (y/n):  ";
        chomp($answer = <STDIN>);
        if ("$answer" =~ /[yY]/) {
                do {
                        my $count = 0;                          ## set author count to zero
                        if ($count <= 1) {
                                $countword = "first";
                        }
                        else {
                                $countword = "next";
                        }
                        print "\n\n\tPlease enter the author\'s name:  ";
                        ## $count++;                    	## increment author count by one
                        chomp($name = <STDIN>);
                        $authors = join(';',$authors,$name);
                        $authors =~ s/^;//;
                } while ($name)
        }
        else {
                print "\n\n\tPlease enter the author\'s name:  ";
                chomp($authors = <STDIN>);
        }
        return $authors;
}

sub KEY_INFO {
##
## create/determine search key based on the 1st four letters of the 1st two words of the title
##
        my @key_source = ();
        my $key_source;
        my $pre_key0;
        my $pre_key1;
        print "\n\n\tPlease enter the title of the book:  ";
        chomp($title = <STDIN>);
        @key_source = split(' ',$title);                        ## array comprised of the individual words of the title
        chomp($pre_key0 = substr($key_source[0], 0, 4));        ## get 1st four letters of 1st word of title
        if ($key_source[1]) {                                   ## tests for existence of 2nd word of title.  If it exists,
                                                                ## get the 1st four letters, otherwise null string and warning.
                chomp($pre_key1 = substr($key_source[1], 0, 4));
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
        return $title;
}

sub BOOK_INFO {
        AUTHOR_INFO;
        KEY_INFO;
        print "\n\n\tPlease enter the isbn of the book:  ";
        chomp($isbn = <STDIN>);
        print "\n\n\tPlease enter the publisher of the book:  ";
        chomp($publisher = <STDIN>);
        print "\n\n\tPlease enter the book's year of publication:  ";
        chomp($pubyear = <STDIN>);
        print "\n\n\tPlease enter the book's edition:  ";
        chomp($edition = <STDIN>);
        print "\n\n\tPlease enter the price of the book:  ";
        chomp($price = <STDIN>);
        $book_info = join(":",$title,$authors,$isbn,$publisher,$pubyear,$edition,$price);
}

sub ADD {
        my $response = "yes";
        while ("$response" =~ /[yY]/) {
                BOOK_INFO;

                # tests to determine if the record to be added already exists.  If so, prints an warning message,
                # and then asks if you want to replace the record.  If so, the existing record is deleted and the
                # "new" record is appended to the end of the database.  If not, no action is taken.
                # If the record does not exist, it is added.
                dbmopen (%book_list,"book_db",0644) || die "can't open book_db database file";
                if ($book_list{"@name"}) {
                        print"\n\n\"$key\" already exists in the database.  Would you like to replace the existing record (yes/no)?  ";
                        chomp(my $answer = <STDIN>);
                        if ("$answer" =~ /[yY]/) {
                                delete($book_list{"$key"});
                                $book_list{"$key"} = "$book_info";
                                print "\n\n\t\tThe record for \"$key\" has been replaced.\n"
                        } else {
                                print "\n\n\t\"$key\" won't be added to the database.\n\n";
                        }
                } else {
                        $book_list{"$key"} = "$book_info";
                }
                dbmclose (%book_list);

                print "\n\n\tDo you want to $action a record for another book (yes/no)?  ";
                chomp($response = <STDIN>);
        }
}

sub MODIFY {
        my $response = "yes";
        while ("$response" =~ /[yY]/) {
                BOOK_INFO;

                # tests to determine if the record being modified exists.  If not, prints an error message.
                # If so, deletes the existing record and appends the "new" record to the end of the database.
                dbmopen (%book_list,"book_db",0644) || die "can't open book_db database file";
                if (! $book_list{"$key"}) {
                        print"\n\n\"$key\" does not exist in the database.  Would you like to add this record (yes/no)?  ";
                        chomp(my $answer = <STDIN>);
                        if ("$answer" =~ /[yY]/) {
                                $book_list{"$key"} = "$book_info";
                        } else {
                                print "\n\n\t\"$key\" won't be added to the database.\n\n";
                        }
                } else {
                        delete($book_list{"$key"});
                        $book_list{"$key"} = "$book_info";
                }
                dbmclose (%book_list);

                print "\n\n\tDo you want to $action a record for another book (yes/no)?  ";
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
                        dbmopen (%book_list,"book_db",0644) || die "can't open book_db database file";
                        if (! $book_list{"$key"}) {
                                print"\n\n\"$key\" does not exist in the database.\n\n";
                        } else {
                                ($title,$authors,$isbn,$publisher,$pubyear,$edition,$price)=split(":",$book_list{"$key"});
                                print "\n\n\tTitle\t\t\t=\t$title\n";
                                print "\tAuthor\(s\)\t\t=\t";
                                if("$authors" =~ /\;/) {
                                        my @local_authors = split(";",$authors);
                                        while ($x = shift @local_authors) {
                                                print "$x\, ";
                                        }
                                        # foreach $x (@local_authors) {
                                                # print "$x\t";
                                        # }
                                        print "\n"
                                } else {
                                        print "\tAuthor\t\t\t=\t$authors\n";
                                }
                                print "\tISBN\t\t\t=\t$isbn\n";
                                print "\tPublisher\t\t=\t$publisher\n";
                                print "\tYear of publication\t=\t$pubyear\n";
                                print "\tEdition\t\t\t=\t$edition\n";
                                print "\tPurchase Price\t\t\t=\t$price\n\n\n";
                        }
                        dbmclose (%book_list);
                } elsif ("$choice" =~ /^[rR]/) {
                        KEY_INFO;
                        # tests to determine if the record to be listed exists.  If not, prints an error message.
                        # If so, displays the pertinent record.
                        dbmopen (%book_list,"book_db",0644) || die "can't open book_db database file";
                        if (! $book_list{"$key"}) {
                                print"\n\n\"$key\" does not exist in the database.\n\n";
                        } else {
                                print("\n\t\t", $key, ' = ', $book_list{"$key"}, "\n");
                        }
                        dbmclose (%book_list);
                } else {
                        print "\n\n\tNo valid display option chosen!!!\n";
                }
                print "\n\n\tDo you want to $action a record for another book (yes/no)?  ";
                chomp($response = <STDIN>);
        }
}

sub LIST {
        my $response = "yes";
        my $choice;
        my $x;
        my $data_file = "book_db";
        print "\n\n\tDo you want to view the record in \(C\)olumnar or \(R\)ow format:  ";
        chomp($choice = <STDIN>);
        while ("$response" =~ /[yY]/) {
                dbmopen (%book_list,"book_db",0644) || die "can't open book_db database file";
                foreach $key (sort(keys(%book_list))) {
                        print("\n\t", $key, ' = ', $book_list{"$key"}, "\n");
                        # printf("\$%s{%s} = '%s'", $data_file, $key, $book_list{$key}, "\n");
                }
                dbmclose (%book_list);

                print "\n\n\tDo you want to $action all records in the database again (yes/no)?  ";
                chomp($response = <STDIN>);
        }
}

sub DELETE {
        my $response = "yes";
        my $response2 = "no";
        while ("$response" =~ /[yY]/) {
                KEY_INFO;

                # tests to determine if the record to be deleted exists.  If not, prints an error message.
                # If so, deletes the pertinent record.
                dbmopen (%book_list,"book_db",0644) || die "can't open book_db database file";
                if (! $book_list{"$key"}) {
                        print"\n\n\"$key\" does not exist in the database.\n\n";
                } else {
                        print "\n\n\tHere is the entry you want to delete:\n";
                        print("\n\t\t", $key, ' = ', $book_list{"$key"}, "\n");
                        print "\n\tAre you sure you want to delete it (yes/no)?\n\tPlease type the entire word \"yes\" or the entire word \"no\":  ";
                        chomp($response2 = <STDIN>);
                        if ("$response2" =~ /^[yY]es/) {
                                delete($book_list{"$key"});
                                print"\n\t\t\"$key\" has been deleted from the database.\n\n";
                        } elsif ("$response2" =~ /^[nN]o/) {
                                print"\n\t\t\"$key\" will not be deleted from the database.\n\n";
                        } else {
                                print "\n\n\tYou gave an inappropriate response -- no action will be taken.\n\n";
                        }
                }
                dbmclose (%book_list);

                print "\n\n\tDo you want to $action a record for another book (yes/no)?  ";
                chomp($response = <STDIN>);
        }
}

##
## This is the main routine of the script
##

my $reply = "";
until ("$reply" =~ /^[qQ]uit/) {
        print "\n\n\tPlease choose one of the options below:";
        print "\n\n\t\t\(A\/a\)dd an entry for a book";
        print "\n\t\t\(M\/m\)odify an entry for a book";
        print "\n\t\t\(V\/v\)iew an entry for a book";
        print "\n\t\t\(L/\l\)ist all records";
        print "\n\t\t\(D\/d\)elete an entry for a book";
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

