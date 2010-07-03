;;; recent.el --- make new file/recent menu and list recent visited files.

;; Copyright 2001 Patrick Gundlach

;; Author: Patrick Gundlach <patrick@gundla.ch>
;; Created 21 April 2001
;; Version 1.0a
;; Keywords: convenience 
;; File Version: $Revision: 1.4 $
;; Last Change: Sun Oct 14 17:54:45 2001

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; version 2

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;; http://www.fsf.org/copyleft/gpl.html 


;;; Commentary:

;; put in an emacs load path and write the following line into your
;; .emacs file: 
;;
;; (require 'recent)

;; This file will add a submenu to the Files menu with the last files
;; visited. It also gives a command line interface invoked with 
;; M-x recent
;; Tested only with emacs, not xemacs! Please send me bug-reports!

 

;;; Code:

(message "Loading recent")
(add-hook 'find-file-hooks
	  'recent-new-name)


(defvar recent-num-of-entries 10
  "Number of entries in recent menu")
(defvar recent-filename "~/.recent-emacs"
  "Filename to save recent files in")


(defvar menu-bar-recent-menu (make-sparse-keymap "Recent")
  "For recent menu")
(defvar recent-files nil
  "List of files recently loaded")
(defvar recent-menu-made nil
  "Files/Recent menu is built")


(defun recent-new-name ()
  "Add filename to the internal recent list and do all necessary stuff"
  (recent-list-add (buffer-file-name))
  )

(defun recent-list-add (filename)
  "Adds filename to internal list"
  ;; don't put my savefile in list
  (unless (equal filename (expand-file-name recent-filename))
    ;; remove if already in list (because we want to put it on 'top')
    (setq recent-files (delete filename recent-files))

    ;; delete first elt if too long
    (if (>= (length recent-files) recent-num-of-entries)
	(setq recent-files (cdr recent-files)))

    ;; add this file and make menu if necessary or update menu
    (setq recent-files (append recent-files (list filename)))
    (if recent-menu-made
	(recent-update-menu)
      (recent-prepare-menu))

    ;; put all this stuff into a separate buffer
    (save-excursion
      (find-file recent-filename)
      (delete-region (point-min) (point-max))
      (goto-char (point-min))
      ;; do this w/ mapcar? -- pg 10/2001
      (let ((i 0))
	(while (< i recent-num-of-entries)
	  (progn 
	    ;; don't insert if no file is in this slot
	    (if (nth i recent-files)
		(insert (nth i recent-files) "\n"))
	    (setq i (1+ i))
	    )))
      (basic-save-buffer)
      (kill-this-buffer)))
  )

(defun recent-prepare-menu ()
  "show menu if recent-files not nil"
  (unless recent-menu-made 
    (if recent-files
	(progn
	  (define-key menu-bar-files-menu [recent]
	    (cons "Recent" menu-bar-recent-menu))
	  (setq recent-menu-made t)
	  (recent-update-menu))))
  )

(defun recent-find-file ()
  ""
  (interactive)
  ;; This is a HACK! The menu is as if you have typed a key
  ;; sequene. So just check what the user has typed in. For example :
  ;; 'menu-bar files recent C-h' means that the user has requested the
  ;; last 9th (C-@=1, C-a=2, C-b=3, ...) file. 
  ;; The file number is stored in last elt of the vector
  ;; this-command-keys-vector. 

  (let ((fileno (aref (this-command-keys-vector) 
		      (1- (length (this-command-keys-vector))))))
    (find-file (nth fileno recent-files)))
  )

(defun recent-update-menu ()
  "Updates the recent files shown in menu Files/Recent"
  ;; all menu items will point to recent-find-file. recent-find-file
  ;; will distinguish the menu items by the associated number. Just
  ;; evaluate menu-bar-recent-menu to find out the structure.
  (let ((i 0))
    (while (< i recent-num-of-entries)
      (progn 
	;; the number 0 will be the lowest menuitem
	(define-key menu-bar-recent-menu (string i)
	  (cons (nth i recent-files) 'recent-find-file))
	(setq i (1+ i))
	)))
  )

(defun recent-read-list ()
  "read recent-list from file"
  (setq recent-files nil)
  (save-excursion
    (find-file recent-filename)
    (widen)
    (goto-char (point-min))
    ;; insert one line at a time to the recent-files but at most the
    ;; number in menubar
    (let ((i 0)
	  (beg 0))
      (while (< i recent-num-of-entries)
	(setq beg (point))
	(beginning-of-line)
	(if (re-search-forward "^.+$" nil t)
	    (setq recent-files 
		  (append recent-files 
			  (list (buffer-substring beg (point))))))
	(forward-line)
	(setq i (1+ i))
	))
    (kill-this-buffer))
  )
(defun recent ()
  "Prompts for a recent file to be displayed"
  (interactive)
  (let (completions ; all possible filenames (unexpanded)
	filetofind  ; the file (unexpanded) to find         .vi
	expanded)   ; the file to find (expanded): /home/pg/.vi
    ;; make a list like 
    ;; ((".emacs" "/home/pg/.emacs") ("recent.el" "/home....") ...) 
    (setq completions 
	  (mapcar '(lambda (x)
		     (list (file-name-nondirectory x) x))
		  recent-files))
    (setq filetofind 
	  (completing-read "Recent file to visit: " completions nil t))
    (if (> (length filetofind) 0)
	(progn 
	  (setq expanded (car (cdr (assoc filetofind completions))))
	  (recent-list-add expanded)
	  (find-file expanded)))))


(recent-read-list)
(recent-prepare-menu)


;; Change Log:
;; V1.0 -> V1.0a
;;         M-x recent added, licence issue made clear.



(provide 'recent)
(message "Loading recent...done")
;;; recent.el ends here

