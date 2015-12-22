#lang racket
(require 2htdp/batch-io
         xml/plist
         racket/runtime-path
         "configuration.rkt")

(provide user-category
         save-user-category
         get-plist-minutes
         get-plist-hours
         PLIST-FILE
         disable-notifications
         notifications-disabled?
         save-notification-time-h
         save-notification-time-m)

(define-runtime-path PATH-TO-HERE ".")

; Name of the txt file containing the preferences.
(define preferences-file (rel-dir "preferences.txt"))

; Write the preferences to a txt file on the disk.
(define (save user)
  (write-file preferences-file user))

; Loads previous set preferences (if existing)
(define preferences
  (if (file-exists? preferences-file)
      (read-lines preferences-file)
      '("0")))

; A UserCategory is one of:
; - Student: 0
; - Professor: 1
; - Associate: 2

; save-user-category: UserCategory
; Saves the given UserCategory id to the first line of the preferences file.
(define (save-user-category id)
  (save (number->string id)))

; user-category: UserCategory
; Retrieves the UserCategory stored in the first line of the preferences file.
(define user-category
  (string->number (first preferences)))

; ========================
; = Notification Manager =
; Hour and Minute values set in the App Preferences are saved into the .plist file
; which is then loaded by OSX launchd

(define PLIST-HOME-PATH "Library/LaunchAgents/ch.usi.λunchtime.notify.plist")

; Absolute path to ~/Library/LaunchAgents
(define PLIST-FILE (path->string (build-path (find-system-path 'home-dir)
                                             PLIST-HOME-PATH)))

; notifications-disabled?: Boolean
; By default notifications are disabled, as the .plist file doesnt exist
(define notifications-disabled?
  (not (file-exists? PLIST-FILE)))

; plist-base: Integer Integer -> plist-dict
; Returns the plist dictionary updated with the given Hour and Minute values.
(define (plist-base hours minutes)
  (list 'dict
        (list 'assoc-pair "Label" "ch.usi.λunchtime.notify")
        (list 'assoc-pair
              "ProgramArguments"
              (list 'array (if RELEASE-BUILD
                               (path->string (build-path (find-system-path 'home-dir) (string->path (rel-dir "scripts/notify.sh"))))
                               (path->string (build-path PATH-TO-HERE "scripts/notify.sh")))))
        (list 'assoc-pair
              "StartCalendarInterval"
              (list 'dict (list 'assoc-pair "Hour"
                                (list 'integer hours))
                    (list 'assoc-pair "Minute" (list 'integer minutes))))))

; save-plist: Integer Integer output-port
; Updates the plist file and loads it to be executed by launchd
; NOTE: output-port must be closed
(define (save-plist hours minutes out) 
  (begin
    (write-plist (plist-base hours minutes) out)
    (close-output-port out)
    (system (string-append "launchctl unload -w ~/" PLIST-HOME-PATH))
    (system (string-append "launchctl load -w ~/"PLIST-HOME-PATH))))

; disable-notifications: Boolean
; If notifications are disabled, deletes .plist file
; Otherwise, default .plist is placed again into the correct system folder
(define (disable-notifications disable? hours minutes)
  (if disable?
      (begin
        (system (string-append "launchctl unload -w ~/" PLIST-HOME-PATH))
        (system (string-append "rm ~/" PLIST-HOME-PATH)))
      (save-plist hours minutes
                  (open-output-file PLIST-FILE #:exists 'replace))))

; save-notification-time : NotificationTime
; Saves the given NotificationTime id to the second line of the preferences file.
(define (save-notification-time-h id)
  (save-plist id
              (get-plist-minutes (open-input-file PLIST-FILE))
              (open-output-file PLIST-FILE #:exists 'replace)))

; save-notification-time-m : NotificationTime
; Saves the given NotificationTime id to the second line of the preferences file.
(define (save-notification-time-m id)
  (save-plist (get-plist-hours (open-input-file PLIST-FILE))
              id
              (open-output-file PLIST-FILE #:exists 'replace)))

; get-plist-hours: input-port -> Integer
; Returns the <key>Hour</key> value in the given file
(define (get-plist-hours in)
  (second (third (second (third (fourth (read-plist in)))))))

; get-plist-minutes: input-port -> Integer
; Returns the <key>Minute</key> value in the given file
(define (get-plist-minutes in)
  (second (third (third (third (fourth (read-plist in)))))))