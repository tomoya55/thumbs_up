2010-09-22
==========
* Changed vote date type to integer
* True votes are now 1, False votes are now -1
* Added option to store the vote count on the voteable table
* Used code from other vote_fu fork http://github.com/kandadaboggu/vote_fu
* Most features outside of the changes are untested

2010-08-03
==========
* Renamed to ThumbsUp from vote\_fu.
* Updated for Rails 3, using ActiveRecord/Arel.
* Cleaned up some dead code, some shitty code, and made a few methods take up quite a lot less memory and time (voters\_who\_voted).
* Removed example code.
* Fixed karma.