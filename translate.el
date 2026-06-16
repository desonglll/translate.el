;;; translate.el --- Translate using trans -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2026 Carl
;;
;; Author: Carl <carl@Carls-MacBook-Air.local>
;; Maintainer: Carl <carl@Carls-MacBook-Air.local>
;; Created: June 16, 2026
;; Modified: June 16, 2026
;; Version: 0.0.1
;; Keywords: abbrev bib c calendar comm convenience data docs emulations extensions faces files frames games hardware help hypermedia i18n internal languages lisp local maint mail matching mouse multimedia news outlines processes terminals tex text tools unix vc wp
;; Homepage: https://github.com/desonglll/translate
;; Package-Requires: ((emacs "24.4"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:

(defun translate-hello-world()
  "Hello world from translate-hello-world."
  (interactive)
  (message "hello world from translate."))

(defun translate-get-selection()
  "Get content in selection area."
  (interactive)
  (let ((input
         (if (use-region-p)
             (buffer-substring-no-properties (region-beginning) (region-end))
           (thing-at-point 'word t))))
    (if (string-blank-p input)
        (progn
          nil)
      (progn
        (string-trim input)))))

(defun translate-get-translation(text)
  "Get translation of TEXT using trans."
  (let ((cmd (format "trans -brief :zh %s" (shell-quote-argument text))))
    (string-trim (shell-command-to-string cmd))))

;;;###autoload
(defun translate()
  "Translate."
  (interactive)
  (let ((text (translate-get-selection)))
    (when text
      (let ((result (translate-get-translation text)))
        (message "result: %s" result)))))

(provide 'translate)
;;; translate.el ends here
