(defvar clocker-packages
  '(clocker)
  "clocker dependencies")

(defcustom clocker-enable-on-initialize nil
  "Enables clocker's features on initialization."
  :group 'clocker)

(defadvice spacemacs/mode-line-prepare-left (around compile)
  (setq ad-return-value (clocker-add-clock-in-to-mode-line ad-do-it)))

(defun clocker/init-clocker ()
  (when clocker-enable-on-initialize
    (use-package powerline
      :config
      (use-package clocker
        :config
        (progn
          (add-hook 'clocker-mode-hook (lambda () (ad-activate 'spacemacs/mode-line-prepare-left)))
          (clocker-mode 1))))))
