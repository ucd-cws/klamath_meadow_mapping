# make project version controlled
# see https://happygitwithr.com/existing-github-last.html

library(usethis)

# set up Git in Existing Project
usethis::use_git()

# now create a new Github Repo on web (best for CWS account), or 

# To set up in Personal Github Page:
# usethis::use_github()

# then in shell/Terminal:
# git remote add origin git@github.com:ucd-cws/klamath_meadow_mapping.git

# and add/push changes:
# git push --set-upstream origin master