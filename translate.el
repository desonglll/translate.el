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

(require 'json)
(require 'seq)
(require 'url)
(require 'subr-x)

(defgroup translate nil
  "Translate text from Emacs."
  :group 'convenience)

(defcustom translate-volcengine-api-key nil
  "API key for Volcengine machine translation.

Set this from your main configuration with `getenv' instead of
writing the key into this package file."
  :type '(choice (const :tag "Unset" nil) string)
  :group 'translate)

(defcustom translate-volcengine-api-key-env-var "VOLCENGINE_TRANSLATE_API_KEY"
  "Environment variable used as fallback for the Volcengine API key."
  :type 'string
  :group 'translate)

(defcustom translate-volcengine-endpoint
  "https://openspeech.bytedance.com/api/v3/machine_translation/matx_translate"
  "Volcengine machine translation endpoint."
  :type 'string
  :group 'translate)

(defcustom translate-volcengine-resource-id "volc.speech.mt"
  "Volcengine machine translation resource id."
  :type 'string
  :group 'translate)

(defcustom translate-volcengine-target-language "zh"
  "Default target language for `translate-volcengine'."
  :type 'string
  :group 'translate)

(defcustom translate-volcengine-source-language nil
  "Default source language for `translate-volcengine'.

When nil or an empty string, Volcengine detects the source language
automatically."
  :type '(choice (const :tag "Auto detect" nil) string)
  :group 'translate)

(defcustom translate-volcengine-ark-api-key nil
  "API key for Volcengine Ark translation."
  :type '(choice (const :tag "Unset" nil) string)
  :group 'translate)

(defcustom translate-volcengine-ark-api-key-env-vars
  '("ARK_API_KEY" "VOLCENGINE_ARK_API_KEY")
  "Environment variables used as fallback for the Volcengine Ark API key."
  :type '(repeat string)
  :group 'translate)

(defcustom translate-volcengine-ark-endpoint
  "https://ark.cn-beijing.volces.com/api/v3/chat/completions"
  "Volcengine Ark Chat Completions endpoint."
  :type 'string
  :group 'translate)

(defcustom translate-volcengine-ark-model "doubao-seed-translation-250915"
  "Default Volcengine Ark model for `translate-volcengine-ark'."
  :type 'string
  :group 'translate)

(defcustom translate-volcengine-ark-target-language "zh"
  "Default target language for `translate-volcengine-ark'."
  :type 'string
  :group 'translate)

(defcustom translate-volcengine-ark-source-language nil
  "Default source language for `translate-volcengine-ark'.

When nil or an empty string, the model detects the source language
automatically."
  :type '(choice (const :tag "Auto detect" nil) string)
  :group 'translate)

(defun translate-hello-world()
  "Hello world from translate-hello-world."
  (interactive)
  (message "hello world from translate."))

(defun translate-find-nearest-word()
  "Find nearest word."
  (or
   (thing-at-point 'word t)
   (save-excursion
     (backward-word)
     (thing-at-point 'word t))
   (save-excursion
     (forward-word)
     (thing-at-point 'word t))))

(defun translate-get-selection()
  "Get content in selection area."
  (interactive)
  (let ((input
         (if (use-region-p)
             (buffer-substring-no-properties (region-beginning) (region-end))
           (thing-at-point 'word t))))
    (cond
     ((null input) (translate-find-nearest-word))

     ((string-blank-p input) (translate-find-nearest-word))
     (t (string-trim input)))))

(defun translate-get-translation-argos(text)
  "Get translation of TEXT using argos."
  (let ((cmd (format "argos-translate --from en --to zh %s" (shell-quote-argument text))))
    (string-trim (shell-command-to-string cmd))))


(defun translate-get-translation-trans(text)
  "Get translation of TEXT using trans."
  (let ((cmd (format "trans -brief :zh %s" (shell-quote-argument text))))
    (string-trim (shell-command-to-string cmd))))

(defun translate--first-nonblank (values)
  "Return the first nonblank string in VALUES."
  (seq-find
   (lambda (value)
     (and value (not (string-blank-p value))))
   values))

(defun translate-volcengine--api-key ()
  "Return the configured Volcengine API key."
  (let ((api-key (translate--first-nonblank
                  (list
                   (getenv translate-volcengine-api-key-env-var)
                   (getenv "VOLCENGINE_API_KEY")
                   translate-volcengine-api-key))))
    (if api-key
        (string-trim api-key)
      (user-error
       "Missing Volcengine API key. Set `translate-volcengine-api-key' or %s"
       translate-volcengine-api-key-env-var))))

(defun translate-volcengine-ark--api-key ()
  "Return the configured Volcengine Ark API key."
  (let ((api-key (translate--first-nonblank
                  (append
                   (mapcar #'getenv translate-volcengine-ark-api-key-env-vars)
                   (list translate-volcengine-ark-api-key)))))
    (if api-key
        (string-trim api-key)
      (user-error
       "Missing Volcengine Ark API key. Set `translate-volcengine-ark-api-key' or one of %s"
       (string-join translate-volcengine-ark-api-key-env-vars ", ")))))

(defun translate-volcengine--request-id ()
  "Return a unique request id for Volcengine."
  (md5 (format "%s-%s-%s"
               (float-time)
               (emacs-pid)
               (random most-positive-fixnum))))

(defun translate-volcengine--parse-response ()
  "Parse JSON response from the current `url' buffer."
  (goto-char (point-min))
  (unless (re-search-forward "\r?\n\r?\n" nil t)
    (user-error "Invalid response from Volcengine"))
  (let ((json-object-type 'alist)
        (json-array-type 'list)
        (json-key-type 'symbol))
    (json-read)))

(defun translate-volcengine--translations (response)
  "Extract translation strings from RESPONSE."
  (let ((code (alist-get 'code response))
        (message (alist-get 'message response)))
    (unless (equal code 20000000)
      (user-error "Volcengine translation failed: code=%s message=%s"
                  code message))
    (let* ((data (alist-get 'data response))
           (items (alist-get 'translation_list data))
           (translations
            (delq nil
                  (mapcar (lambda (item)
                            (alist-get 'translation item))
                          items))))
      (unless translations
        (user-error "Volcengine response did not include translations"))
      translations)))

(defun translate-volcengine-ark--message-content (response)
  "Extract message content from a Volcengine Ark RESPONSE."
  (let ((error (alist-get 'error response)))
    (when error
      (user-error "Volcengine Ark translation failed: code=%s message=%s"
                  (alist-get 'code error)
                  (alist-get 'message error))))
  (let* ((choices (alist-get 'choices response))
         (choice (car choices))
         (message (alist-get 'message choice))
         (content (alist-get 'content message)))
    (unless (and content (not (string-blank-p content)))
      (user-error "Volcengine Ark response did not include translation content"))
    (string-trim content)))

(defun translate-volcengine-ark--system-prompt
    (source-language target-language)
  "Return system prompt for SOURCE-LANGUAGE and TARGET-LANGUAGE."
  (string-join
   (delq
    nil
    (list
     "You are a professional translation engine."
     (if (and source-language (not (string-blank-p source-language)))
         (format "Translate from %s to %s." source-language target-language)
       (format "Detect the source language and translate to %s." target-language))
     "Only return the translated text."
     "Preserve the original meaning, formatting, and line breaks where possible."))
   " "))

(defun translate-get-translation-volcengine
    (text &optional source-language target-language)
  "Get translation of TEXT using Volcengine.

SOURCE-LANGUAGE defaults to `translate-volcengine-source-language'.
TARGET-LANGUAGE defaults to `translate-volcengine-target-language'."
  (let* ((source-language (or source-language
                              translate-volcengine-source-language))
         (target-language (or target-language
                              translate-volcengine-target-language))
         (body `((target_language . ,target-language)
                 (text_list . [,text])))
         (url-request-method "POST")
         (url-request-extra-headers
          `(("Content-Type" . "application/json")
            ("X-Api-Key" . ,(translate-volcengine--api-key))
            ("X-Api-Resource-Id" . ,translate-volcengine-resource-id)
            ("X-Api-Request-Id" . ,(translate-volcengine--request-id))))
         (url-request-data
          (encode-coding-string
           (json-encode
            (if (and source-language
                     (not (string-blank-p source-language)))
                (append body `((source_language . ,source-language)))
              body))
           'utf-8))
         (buffer (url-retrieve-synchronously translate-volcengine-endpoint
                                             t t 30)))
    (unless buffer
      (user-error "Volcengine translation request timed out"))
    (unwind-protect
        (with-current-buffer buffer
          (string-join
           (translate-volcengine--translations
            (translate-volcengine--parse-response))
           "\n"))
      (kill-buffer buffer))))

(defun translate-get-translation-volcengine-ark
    (text &optional source-language target-language)
  "Get translation of TEXT using Volcengine Ark.

SOURCE-LANGUAGE defaults to `translate-volcengine-ark-source-language'.
TARGET-LANGUAGE defaults to `translate-volcengine-ark-target-language'."
  (let* ((source-language (or source-language
                              translate-volcengine-ark-source-language))
         (target-language (or target-language
                              translate-volcengine-ark-target-language))
         (messages
          `[((role . "system")
             (content . ,(translate-volcengine-ark--system-prompt
                          source-language target-language)))
            ((role . "user")
             (content . ,text))])
         (body `((model . ,translate-volcengine-ark-model)
                 (messages . ,messages)
                 (temperature . 0)))
         (url-request-method "POST")
         (url-request-extra-headers
          `(("Content-Type" . "application/json")
            ("Authorization" . ,(concat "Bearer "
                                        (translate-volcengine-ark--api-key)))))
         (url-request-data
          (encode-coding-string (json-encode body) 'utf-8))
         (buffer (url-retrieve-synchronously translate-volcengine-ark-endpoint
                                             t t 30)))
    (unless buffer
      (user-error "Volcengine Ark translation request timed out"))
    (unwind-protect
        (with-current-buffer buffer
          (translate-volcengine-ark--message-content
           (translate-volcengine--parse-response)))
      (kill-buffer buffer))))

;;;###autoload
(defun translate-trans(&optional arg)
  "Translate.
With prefix argument ARG, prompt for manual input."
  (interactive "P")
  (let ((text
         (if arg
             (read-string "Translate text: ")
         (translate-get-selection))))
    (when text
      (message "text: %s" text)
      (let ((result (translate-get-translation-trans text)))
        (message "result: %s" result)))))

;;;###autoload
(defun translate-argo(&optional arg)
  "Translate using argo.
With prefix argument ARG, prompt for manual input."
  (interactive "P")
  (let ((text
         (if arg
             (read-string "Translate text: ")
           (translate-get-selection))))
    (when text
      (message "text: %s" text)
      (let ((result (translate-get-translation-argos text)))
        (message "result: %s" result)))))

;;;###autoload
(defun translate-volcengine (&optional arg)
  "Translate using Volcengine machine translation.
With prefix argument ARG, prompt for manual input."
  (interactive "P")
  (let ((text
         (if arg
             (read-string "Translate text: ")
           (translate-get-selection))))
    (when text
      (message "text: %s" text)
      (let ((result (translate-get-translation-volcengine text)))
        (message "result: %s" result)))))

;;;###autoload
(defun translate-volcengine-ark (&optional arg)
  "Translate using Volcengine Ark.
With prefix argument ARG, prompt for manual input."
  (interactive "P")
  (let ((text
         (if arg
             (read-string "Translate text: ")
           (translate-get-selection))))
    (when text
      (message "text: %s" text)
      (let ((result (translate-get-translation-volcengine-ark text)))
        (message "result: %s" result)))))

(provide 'translate)
;;; translate.el ends here
