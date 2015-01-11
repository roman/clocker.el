(defvar clocker-packages
  '(clocker)
  "clocker dependencies")

(defcustom clocker-enable-on-initialize nil
  "Enables clocker's features on initialization."
  :group 'clocker)

(defadvice spacemacs/mode-line-prepare-left (around compile)
        (setq ad-return-value (clocker/add-clock-in-to-mode-line ad-do-it)))

(defun clocker/init-clocker ()
  (use-package org
    :config
    (progn
      (when clocker-enable-on-initialize
        (clocker-mode 1))
      (when (fboundp 'spacemacs/mode-line-prepare-left)
        (ad-activate spacemacs/mode-line-prepare-left)))))
