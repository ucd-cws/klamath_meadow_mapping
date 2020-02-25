# make project version controlled
# see https://happygitwithr.com/existing-github-last.html

library(usethis)

# OPTION 1: Preferably go to website on github for project
# Clone from github, create new project via RStudio version control

# OPTION 2: Set up Git in Existing R Project
usethis::use_git()

# now create a new Github Repo on web (best for CWS account), or 

# then in shell/Terminal:
# git remote add origin git@github.com:ucd-cws/klamath_meadow_mapping.git

# and add/push changes:
# git push --set-upstream origin master