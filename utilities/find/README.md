There is a python parallel version here:
git@github.com:johnbent/pwalk.git
It requires python 3.5 or 3.6.

Everything you need to do to run it is done by the prepare.sh script.

Once you get it, then to run it you edit the 'setup_find' function in the base
'io500.sh' to turn it on.  Also, it relies on the 'pfind.sh' script in this
directory which is copied to the right place by prepare.sh. 
