;; TODO: Improve form selection
;; TODO: Add binding to select and shrink/grow what would be eval'd
(require 'inf-elixir)

(defun esm-recompile ()
  (interactive)
  (esm-send-command "recompile"))

(defun esm-observer ()
  (interactive)
  (esm-send-command ":observer.start()"))

(defun esm--buffer-module-name ()
  ;; Regex stolen from inf-elixir
  (nth 0 (inf-elixir--matches-in-buffer "defmodule \\([A-Z][A-Za-z0-9\._]+\\)\s+")))

(defun esm-break-module ()
  (interactive)
  (let ((module-name (esm--buffer-module-name)))
    (if module-name
        (progn (esm-send-command (format ":debugger.start()"))
               (esm-send-command (format ":int.ni(%s)" module-name))
               (esm-send-command (format ":int.break(%s, %s)" module-name (line-number-at-pos)))
               (message (format "Breakpoint set for %s:%s" module-name (line-number-at-pos))))
      (message "Unable to identify module name for %S" (buffer-name)))))

(defun esm-send-command (cmd)
  (let ((inf-elixir-switch-to-repl-on-send nil))
    (inf-elixir--send cmd)))

(defun esm--eval-previous-form-dwim ()
  "Evaluate the evaluate the `right` form based on the cursor position."
  (interactive)
  (save-excursion
    (unless (= (point) (point-at-bol))
      (backward-sexp))
    (let ((start (point)))
      (forward-sexp)
      (let ((end (point)))
        (esm--eval start end)))))

(defun esm--eval (start end)
  (esm-send-command (buffer-substring start end))
  (pulse-momentary-highlight-region start end))

(defun esm-eval-dwim ()
  (interactive)
  (if (region-active-p)
      (esm--eval (region-beginning) (region-end))
    (esm--eval-previous-form-dwim)))
 
(defvar elixir-scratch-mode-map
  (let ((keymap (make-keymap)))
    (bind-key (kbd "C-<return>") #'esm-eval-dwim keymap)
    (bind-key (kbd "C-c C-c") #'esm-recompile keymap)
    (bind-key (kbd "C-c C-d") #'esm-break-module)
    (bind-key (kbd "C-c o") #'esm-observer)
    keymap))

(define-minor-mode elixir-scratch-mode
  "Enables smart closing of open brackets"
  ;; Initial value
  :init-value nil
  ;; minor mode bindings
  :keymap elixir-scratch-mode-map)

(provide 'elixir-scratch-mode)
