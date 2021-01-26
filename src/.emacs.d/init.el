;;; -*- lexical-binding: t -*-

;; --------
;; table of contents
;; --------
;;
;; 1. packages
;; 2. general
;; 3. gui
;; 4. files, buffers, navigation
;; 5. text editing
;; 6. keybindings
;; 7. languages, autocompletion
;; --------

;; --------
;; 1. packages
;; --------

(require 'package)
(package-initialize)

;; add repositories
(add-to-list 'package-archives' ("melpa" . "https://melpa.org/packages/"))
(add-to-list 'package-archives' ("melpa-stable" . "http://stable.melpa.org/packages/"))
(add-to-list 'package-archives' ("org" . "http://orgmode.org/elpa/"))

;; set up use-package
(when (not (package-installed-p 'use-package))
  (package-refresh-contents)
  (package-install 'use-package))

;; gruvbox-theme
(use-package gruvbox-theme
  :ensure t
  :init
  (load-theme 'gruvbox-dark-hard t))

;; exec-path-from-shell
(when (memq window-system '(mac ns x))
  (use-package exec-path-from-shell
    :ensure t
    :init
    ;; only run in gui
    (exec-path-from-shell-initialize)))

;; undo-tree
(use-package undo-tree
  :ensure t
  :config
  (global-undo-tree-mode))

;; evil-leader (needs to be initialized before evil)
(use-package evil-leader
  :ensure t
  :init
  (global-evil-leader-mode)
  ;; set leader key to comma
  (evil-leader/set-leader ",")
  ;; configure leader commands
  (evil-leader/set-key
    "f" 'counsel-projectile-find-file
    "r" 'counsel-projectile-rg
    "a" "ggvG"))

;; evil
(use-package evil
  :ensure t
  :init
  ;; h and l will wrap to previous and next lines
  (setq evil-cross-lines t)
  ;; keybindings
  (define-key evil-motion-state-map (kbd ";") 'evil-ex)
  (define-key evil-motion-state-map (kbd ":") 'evil-ex)
  (define-key evil-motion-state-map (kbd "C-h") 'evil-window-left)
  (define-key evil-motion-state-map (kbd "C-j") 'evil-window-down)
  (define-key evil-motion-state-map (kbd "C-k") 'evil-window-up)
  (define-key evil-motion-state-map (kbd "C-l") 'evil-window-right)
  ;; normal mode
  (define-key evil-normal-state-map (kbd "SPC") 'evil-ex)
  (define-key evil-normal-state-map (kbd "TAB") 'evil-search-forward)
  (define-key evil-normal-state-map (kbd "u") 'undo-tree-undo)
  (define-key evil-normal-state-map (kbd "C-r") 'undo-tree-redo)
  ;; visual mode
  ;; insert mode
  (define-key evil-insert-state-map (kbd "C-n") 'company-select-next)
  (define-key evil-insert-state-map (kbd "C-p") 'company-select-previous)
  (define-key evil-insert-state-map (kbd "TAB") 'tab-to-tab-stop)
  (define-key evil-insert-state-map (kbd "C-u")
    (lambda ()
      (interactive)
      (evil-delete (point-at-bol) (point))))
  :config
  (evil-mode t))

;; evil-goggles
(use-package evil-goggles
  :ensure t
  :config
  (evil-goggles-mode)
  (setq evil-goggles-pulse t)
  (setq evil-goggles-duration 0.500))

;; page break (for dashbord)
(use-package page-break-lines
  :ensure t
  :config
  (turn-on-page-break-lines-mode))

;; dashboard
(use-package dashboard
  :ensure t
  :config
  (dashboard-setup-startup-hook))

;; projectile
(use-package projectile
  :ensure t
  :init (projectile-mode t))

;; counsel, ivy, swiper
(use-package counsel
  :ensure t
  :init
  ;; use ivy interface for most commands
  (global-set-key (kbd "C-s") 'swiper-isearch)
  (global-set-key (kbd "M-x") 'counsel-M-x)
  (global-set-key (kbd "C-x C-f") 'counsel-find-file)
  (global-set-key (kbd "M-y") 'counsel-yank-pop)
  (global-set-key (kbd "<f1> f") 'counsel-describe-function)
  (global-set-key (kbd "<f1> v") 'counsel-describe-variable)
  (global-set-key (kbd "<f1> l") 'counsel-find-library)
  (global-set-key (kbd "<f2> i") 'counsel-info-lookup-symbol)
  (global-set-key (kbd "<f2> u") 'counsel-unicode-char)
  (global-set-key (kbd "<f2> j") 'counsel-set-variable)
  (global-set-key (kbd "C-x b") 'ivy-switch-buffer)
  (global-set-key (kbd "C-c v") 'ivy-push-view)
  (global-set-key (kbd "C-c V") 'ivy-pop-view)
  (global-set-key (kbd "C-c c") 'counsel-compile)
  (global-set-key (kbd "C-c g") 'counsel-git)
  (global-set-key (kbd "C-c j") 'counsel-git-grep)
  (global-set-key (kbd "C-c L") 'counsel-git-log)
  (global-set-key (kbd "C-c k") 'counsel-rg)
  (global-set-key (kbd "C-c m") 'counsel-linux-app)
  (global-set-key (kbd "C-c n") 'counsel-fzf)
  (global-set-key (kbd "C-x l") 'counsel-locate)
  (global-set-key (kbd "C-c J") 'counsel-file-jump)
  (global-set-key (kbd "C-S-o") 'counsel-rhythmbox)
  (global-set-key (kbd "C-c w") 'counsel-wmctrl)
  (global-set-key (kbd "C-c C-r") 'ivy-resume)
  (global-set-key (kbd "C-c b") 'counsel-bookmark)
  (global-set-key (kbd "C-c d") 'counsel-descbinds)
  (global-set-key (kbd "C-c g") 'counsel-git)
  (global-set-key (kbd "C-c o") 'counsel-outline)
  (global-set-key (kbd "C-c t") 'counsel-load-theme)
  (global-set-key (kbd "C-c F") 'counsel-org-file))

(use-package counsel-projectile
  :ensure t
  :init (counsel-projectile-mode t))

;; org mode
(use-package org
  :ensure t)

;; flycheck
(use-package flycheck
  :ensure t
  :init (global-flycheck-mode))

;; lsp-mode
(use-package lsp-mode
  :ensure t
  :hook (python-mode . lsp-deferred)
  :commands (lsp lsp-deferred))

;; lsp python-mode
(use-package lsp-python-ms
  :ensure t
  :init (setq lsp-python-ms-auto-install-server t)
  :hook (python-mode . (lambda ()
                          (require 'lsp-python-ms)
                          (lsp-deferred))))

;; company
(use-package company
  :ensure t
  :config
  (add-hook 'after-init-hook 'global-company-mode))

;; --------
;; 2. general
;; --------

;; use utf-8 everywhere
(prefer-coding-system 'utf-8)
(set-default-coding-systems 'utf-8)
(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)
(setq default-buffer-file-coding-system 'utf-8)

;; use y/n for prompts
(defalias 'yes-or-no-p 'y-or-n-p)

;; text prompts over dialog boxes
(setq use-dialog-box nil)

;; disable visual and audible bell
(setq ring-bell-function 'ignore)

;; save registers on exit to preserve macros
(savehist-mode 1)
(setq savehist-additional-variables '(register-alist))

;; disable file backups
(setq backup-inhibited t)
(setq auto-save-default nil)

;; custom variables and faces files
(setq custom-file (concat user-emacs-directory "/custom.el"))
(load-file custom-file)

;; --------
;; 3. gui
;; --------

;; frame size
(add-to-list 'default-frame-alist '(width . 180))
(add-to-list 'default-frame-alist '(height . 60))

;; hide gui elements
(tool-bar-mode -1)
(menu-bar-mode -1)
(scroll-bar-mode -1)

;; disable startup message
(defun display-startup-echo-area-message () (message ""))

;; window title
(setq-default frame-title-format "%b %& emacs")

;; show line numbers
(global-display-line-numbers-mode)

;; show empty lines at end of file
(setq-default indicate-empty-lines t)

;; --------
;; 4. files, buffers, navigation
;; --------

;; --------
;; 5. text editing
;; --------

;; tabs and spaces
(setq-default indent-tabs-mode nil)
(setq-default tab-width 2)

;; --------
;; 6. keybindings
;; --------

;; use esc like C-g
(define-key key-translation-map (kbd "ESC") (kbd "C-g"))

;; --------
;; 7. languages, autocompletion
;; --------

;; ignore case for autocompletion
(setq completion-ignore-case t)

;; increase thresholds for lsp-mode
(setq gc-cons-threshold (* 1024 1024 100)) ;; 100mb
(setq read-process-output-max (* 1024 1024)) ;; 1mb

;; use company-capf as lsp-mode provider
(setq lsp-completion-provider :capf)
