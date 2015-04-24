# Summary

`clocker.el` is a an extension for org-mode that facilitates remembering
to clock-in when working on emacs. It also keeps an org-file visible
as you save a file so that you remember to take notes if necessary.

## Clock-In feature

When starting a new coding session, is really easy to forget to
clock-in. As soon as you save your first file clocker will do the
following when not clocked in.

1) It will lookup for a buffer that maps to a file with an `.org`
extension, if clocker.el finds more than one, it will open the first
one it finds.

2) In case (1) fails. It will check your `clocker-issue-format-regex`
setting, and if it is not nil, clocker.el tries to get an issue-id
from your current branch and in combination of your project root and
`clocker-project-issue-folder` (defaults to org) it opens a file in:
`project-root/clocker-project-issue-folder/issue-id.org`

3) In case (2) fails, It will traverse your tree heriarchy, and will
open the closest org file it can finds. Personally I suggest having
an org file on your home directory as a catch all of work I'm doing
in general, and archive to a different org file if necessary.

4) If all the above fail, clocker.el will print a message indicating
that it didn't find any org file to open.

Once an org file is open, it also will ask a silly question which
answer won't matter the only purpuse of this is to break your
concentration so that you remember to clock-in. Probably you will skip
it 3 or 4 times, but at the 5th you are going to give up because of
the slowness that question in mini-buffer causes.

## Keep org file visible at all times

Once the first problem is solved (clocking in), the next thing you
would like to do is to keep notes of everything you are working
on. I've discovered that as long I have an open buffer with an org
file, I don't forget to write down what I am doing. However when this
is not the case, I surely always forget. `clocker.el` helps me by
always keeping the org file visible, in case it is not visible, after
a file is saved it will prompt the org file buffer.

# Spacemacs support

On a private layer, paste the following code:

```elisp

(def your-layer-packages '(clocker))


(defadvice spacemacs/mode-line-prepare-left (around compile)
          (setq ad-return-value (clocker-add-clock-in-to-mode-line ad-do-it)))

(defun your-layer/init-clocker ()
  (use-package clocker
    :config
    (progn
      (ad-activate 'spacemacs/mode-line-prepare-left)
      (clocker-mode 1))))


```

This will add a `CLOCK-IN` message on the left side of your mode-line
when not clocked-in.

# Documentation

Check documentation of variables in the `clocker.el` file.

## Development

Pull requests are very welcome! Please try to follow these simple rules:

* Please create a topic branch for every separate change you make.

* Update the `README.md` file.

* Please **do not change** the version number.

#### Open Commit Bit

clocker.el has an open commit bit policy: Anyone with an accepted
pull request gets added as a repository collaborator.  Please try to
follow these simple rules:

* Commit directly onto the master branch only for typos, improvements
to the README and documentation.

* Create a feature branch and open a pull-request early for any new
features to get feedback.

* Make sure you adhere to the general pull request rules above.

## License

```
clocker.el - Note taker and clock-in enforcer

Copyright (C) 2015  Roman Gonzalez and collaborators.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, org (at
your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
```
