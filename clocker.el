;;; clocker.el --- Note taker and clock-in enforcer
;;; Commentary:

;; Copyright (C) 2015 Roman Gonzalez.

;; Author: Roman Gonzalez <romanandreg@gmail.com>
;; Maintainer: Roman Gonzalez <romanandreg@gmail.com>
;; Version: 0.0.1
;; Package-Requires: ((projectile "0.11.0") (dash "2.10"))
;; Keywords: org

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.  This program is
;; distributed in the hope that it will be useful, but WITHOUT ANY
;; WARRANTY; without even the implied warranty of MERCHANTABILITY or
;; FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
;; License for more details.  You should have received a copy of the
;; GNU General Public License along with this program.  If not, see
;; <http://www.gnu.org/licenses/>.

(require 'dash)
(require 'em-glob)
(require 'org-clock)
(require 'projectile)
(require 'vc-git)

;;; Code:

;;;;;;;;;;;;;;;;;;;;
;; customizable variables

(defface clocker/mode-line-clock-in-face
  '((t (:foreground "white" :background "#F2686C" :inherit mode-line)))
  "Clocker's face for CLOCK-IN mode-line message."
  :group 'clocker)

(defvar clocker-issue-format-regex nil
  "Holds regex that extracts issue-id from a branch namae.

When this value is null, clocker won't infer org file names from
branch names.")

(defvar clocker-extra-annoying t
  "Performs annoying questions to disrupt work concentration when true.

This is recommended if you really want to enforce yourself to
clock-in.")

(defvar clocker-project-issue-folder "org"
  "Name of the directory that will hold the org files per issue.")

(defvar clocker-skip-after-save-hook-on-extensions '("org")
  "Holds file extensions that won't be affected by clocker's `after-save-hook'.

If a file extension is here, the `after-save-hook' won't do any
checks if not clocked in")

;;;;;;;;;;;;;;;;;;;;
;; util

(defun clocker/org-clocking-p ()
  "Check if org clock-in is on."
  (and (fboundp 'org-clocking-p)
       (org-clocking-p)))

(defconst clocker-mode-line-widget
  (powerline-raw "CLOCK-IN "
                 'clocker/mode-line-clock-in-face
                 'l)
  "CLOCK-IN powerline widget.")

(defun clocker/add-clock-in-to-mode-line (lhs)
  "Add a CLOCK-IN string to the mode-line list.

This string is put in the second position on the given mode-line
list (LHS)."
  (let ((new-lhs
         (if (not (clocker/org-clocking-p))
             (-insert-at 1 clocker-mode-line-widget lhs)
           lhs)))
    new-lhs))

;;;;;;;;;;;;;;;;;;;;
;; find buffer with org-file open

(defun clocker/check-clocked-in-with-file-extension? (file-ext)
  "Check if clocker ignores saves on file with extension file-ext"
  (not (-contains? clocker-skip-after-save-hook-on-extensions file-ext)))

(defun clocker/first-org-buffer ()
  "Return first buffer that has an .org extension."
  (->> (buffer-list)
       (--map (buffer-file-name it))
       (--filter (and it (string-match ".org$" it)))
       -first-item))

;;;;;;;;;;;;;;;;;;;;
;; find global org-file (sitting on home most likely)

(defun clocker/get-parent-dir (dir)
  "Return the parent directory path of given DIR."
  (if (or (not dir)
          (string-equal dir "/"))
      nil
    (file-name-directory
     (directory-file-name dir))))

(defun clocker/locate-dominating-file (glob &optional start-dir)
    "Locates a file on the hierarchy tree using a GLOB.

Similar `locate-dominating-file', although accepts a GLOB instead
of simple string.

If START-DIR is not specified, starts in `default-directory`."
    (let* ((dir (or start-dir default-directory))
           (file-found (directory-files dir
                                        nil
                                        (eshell-glob-regexp glob))))
      (cond
       (file-found (concat dir (car file-found)))
       ((not (or (string= dir "/")
                 (string= dir "~/")))
        (clocker/locate-dominating-file glob (clocker/get-parent-dir dir)))
       (t nil))))

(defun clocker/find-dominating-org-file ()
  "Lookup on directory tree for a file with an org extension.

returns nil if it can't find any"
  (clocker/locate-dominating-file "*.org"))

;;;;;;;;;;;;;;;;;;;;
;; find org file per-issue

(defun clocker/issue-org-file (project-root issue-id)
  "Use PROJECT-ROOT and ISSUE-ID to infer a file name."
  (concat project-root
          (file-name-as-directory clocker-project-issue-folder)
          (concat issue-id ".org")))

(defun clocker/get-issue-id-from-branch-name (issue-regex branch-name)
  "Use ISSUE-REGEX to get issue-id from a BRANCH-NAME."
  (when (and issue-regex branch-name (string-match issue-regex branch-name))
    (match-string 0 branch-name)))

(defun clocker/find-issue-org-file ()
  "Infer an org file name from issue number on current's branch name.

This works when the `clocker-issue-format-regex` is not nil."
  (when clocker-issue-format-regex
      (let* ((project-root (projectile-project-root))
             (branch-name (car (vc-git-branches)))
             (issue-id (clocker/get-issue-id-from-branch-name clocker-issue-format-regex
                                                                      branch-name)))
        (and issue-id (clocker/issue-org-file project-root issue-id)))))


;; clocked-in functionality

;;;###autoload
(defun clocker/org-clock-goto (&optional select)
  "Open file that has the currently clocked-in entry, or to the
most recently clocked one.

With prefix arg SELECT, offer recently clocked tasks for selection."
  (interactive "@P")
  (let* ((current (current-buffer))
         (recent nil)
         (m (cond
             (select
              (or (org-clock-select-task "Select task to go to: ")
                  (error "No task selected")))
             ((org-clocking-p) org-clock-marker)
             ((and org-clock-goto-may-find-recent-task
                   (car org-clock-history)
                   (marker-buffer (car org-clock-history)))
              (setq recent t)
              (car org-clock-history))
             (t (error "No active or recent clock task")))))


    (unless (get-buffer-window (marker-buffer m) 0)
      (pop-to-buffer (marker-buffer m) nil t)
      (if (or (< m (point-min)) (> m (point-max))) (widen))
      (goto-char m)
      (org-show-entry)
      (org-back-to-heading t)
      (org-cycle-hide-drawers 'children)
      (org-reveal)
      (if recent
          (message "No running clock, this is the most recently clocked task"))
      (run-hooks 'org-clock-goto-hook)
      (other-window 1))))

;;;;;;;;;;;;;;;;;;;;
;; main functions

;;;###autoload
(defun clocker/open-org-file ()
  "Open an appropiate org file.

It traverses files in the following order:

1) It tries to find an open buffer that has a file with .org
extension, if found switch to it.

2) If 1 is nil and `clocker-issue-format-regex' is not nil, it
   tries to open/create an org file using the issue number on the
   branch

3) If `clocker-issue-format-regex' is nil, it will traverse your
tree hierarchy and finds the closest org file."
  (interactive)
  (let* ((buffer-orgfile (clocker/first-org-buffer))
         (file-orgfile (or buffer-orgfile (clocker/find-issue-org-file)))
         (file-orgfile (or file-orgfile (clocker/find-dominating-org-file))))
    (if file-orgfile
        (find-file file-orgfile)
      (message "clocker: could not find/infer org file."))))

(defun clocker/after-save-hook ()
  "Execute `'clocker/open-org-file' and asks annoying questions if not clocked-in."
  (interactive)
  (let* ((current-file (buffer-file-name))
         (current-ext (and current-file (file-name-extension current-file))))
    (if (and current-file
             (clocker/check-clocked-in-with-file-extension? current-ext))
        (if (not (clocker/org-clocking-p))
            (progn
              (clocker/open-org-file)
              (when clocker-extra-annoying
                (yes-or-no-p "Did you remember to clock in?")))
          (clocker/org-clock-goto)))))


(provide 'clocker)

;;; clocker.el ends here
