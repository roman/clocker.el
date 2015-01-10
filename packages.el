(defvar clocker-packages
  '(org)
  "clocker dependencies")

(defvar clocker-enable-after-save-hook nil
  "Enables clocker's `after-save-hook' on spacemacs when true.")

(defun clocker/init-org ()
  (use-package org
    :config
    (progn
      (when clocker-enable-after-save-hook
        (add-hook 'after-save-hook 'clocker/after-save-hook))
      (when (fboundp 'spacemacs/mode-line-prepare-left)
        (defadvice spacemacs/mode-line-prepare-left (around compile activate)
        (setq ad-return-value (clocker/add-clock-in-to-mode-line ad-do-it)))))))

