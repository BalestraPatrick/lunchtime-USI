#lang racket
(require 2htdp/batch-io
         racket/date
         test-engine/racket-tests
         "configuration.rkt")

(provide today
         is-menu-out-of-date?
         string-selected-date)

; Name of the file containing the current week dates
(define TIMESPAN (rel-dir "menus/timespan.txt"))

; If file doesn't exist, set UNIX time 0
(define week-dates
  (if (file-exists? TIMESPAN)
      (first (read-lines TIMESPAN))
      "01.01.1970 - 01.01.1970"))

; Current day of the week
(define today
  (date-week-day (current-date)))

; string-date-for-selected-day: Integer -> String
(define (string-selected-date day)
  (date->string
   (seconds->date
    (find-seconds (date-second (current-date))
                  (date-minute (current-date))
                  (date-hour (current-date))
                  (+ (date-day (current-date)) (- day today))
                  (date-month (current-date))
                  (date-year (current-date))
                  #t))))


; week-boundaries: String -> List<String>
; Parse the week starting and ending day from the given formatted string.
; Example:
;    ("30.11.2015 - 04.12.2015") --> '("30.11.2015" "04.12.2015")
(define week-boundaries
  (regexp-split #rx" - " week-dates))

; split-day-month-year : String -> List<String>
; Split a date of the in the format 06.11.2015 into '("06" "11" "2015").
; In this way we can build the exact timestamp.
(define (split-day-month-year date)
  (regexp-split #rx"\\." date))
; Tests
(check-expect (split-day-month-year "06.11.2015") '("06" "11" "2015"))
(check-expect (split-day-month-year "16.05.2015") '("16" "05" "2015"))

; convert-to-unix : String Number -> List<String>
; Given a date and an hour, returns the corresponding UNIX timestamp.
(define (convert-to-unix date hour)
  (find-seconds 0 0 hour ; sec min hour
                (string->number (first date))
                (string->number (second date))
                (string->number (third date))
                #t))
; Tests
(check-expect (convert-to-unix (split-day-month-year "06.11.2015") 23) 1446847200)
(check-expect (convert-to-unix (split-day-month-year "05.12.2015") 23) 1449352800)

; Monday (at 8AM) timestamp of the current week
; List<String>
(define monday
  (convert-to-unix (split-day-month-year (first week-boundaries))
                   8))

; Friday (at 11PM) timestamp of the current week
; List<String>
(define friday
  (convert-to-unix (split-day-month-year (second week-boundaries))
                   23))

; is-menu-out-of-date : Boolean
; Check if the menu is up to date for this week and if we have already downloaded it.
(define is-menu-out-of-date?
  (or (not (file-exists? (rel-dir "menus/timespan.txt")))
      (not (< monday (current-seconds) friday))))

; Run check-expects
(test)