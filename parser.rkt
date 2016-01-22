#lang racket
; Authors: Patrick Balestra and Lara Bruseghini
; PDF Parser for λunchtime @ USI
(require test-engine/racket-tests
         racket/system
         2htdp/batch-io
         racket-poppler
         racket/runtime-path
         "date-checker.rkt"
         "configuration.rkt")

(provide menu-for-day
         day-menu
         day-menu-full
         day-menu-single
         day-menu-veggie)

; ========================
; = PARTIAL MENU PARSING =

; Name of the txt file containing the text of the menu
(define menu-file (rel-dir "output/menu.txt"))

; Path of the download script to be bundled inside the release.
(define download-script (rel-dir "scripts/download.sh"))

; Path of the check script to be bundled inside the release.
(define check-script (rel-dir "scripts/check.sh"))

; x: List<Number> -> String
; Given '(x1 y1 x2 y2) returns the string of the rounded x1 value (to be given as bash script argument)
(define (x coord)
  (number->string (inexact->exact (round (first coord)))))
; Test
(check-expect (x '(1.1 2.2 3.3 4.4)) "1")

; y1: List<Number> -> String
; Given '(x1 y1 x2 y2) returns the string of the rounded y1 value (to be given as bash script argument)
(define (y1 coord)
  (number->string (inexact->exact (round (second coord)))))
; Test
(check-expect (y1 '(1.1 2.2 3.3 4.4)) "2")

; y2: List<Number> -> String
; Given '(x1 y1 x2 y2) returns the string of the rounded y2 value 
(define (y2 coord)
  (number->string (inexact->exact (round (fourth coord)))))
; Test
(check-expect (y2 '(1.1 2.2 3.3 4.4)) "4")

; run-check: pdf? -> Boolean
; Computes the coordinates of each day name into the given pdf and runs check.sh
(define (run-check menu-pdf)
  (local (; List<List<Number>>
          ; List of points coordinates '(x1 y1 x2 y2)
          (define day-coords
            (list (page-find-text menu-pdf "luned")
                  (page-find-text  menu-pdf "marted")
                  (page-find-text  menu-pdf "mercoled")
                  (page-find-text  menu-pdf "gioved")
                  (page-find-text  menu-pdf "venerd")))
          
          ; To extract each day's coords from day-coords
          (define mon (lambda (x) (first (first x))))
          (define tue (lambda (x) (first (second x))))
          (define wed (lambda (x) (first (third x))))
          (define thu (lambda (x) (first (fourth x))))
          (define fri (lambda (x) (first (fifth x)))))
    
    (system* check-script
             (x (mon day-coords))
             (x (tue day-coords))
             (x (wed day-coords))
             (x (thu day-coords))
             (x (fri day-coords))
             (y2 (mon day-coords))
             (y1 (first (page-find-text menu-pdf "modifiche")))
             (rel-dir ""))))

; Run script download.sh
(if (or (not (file-exists? menu-file))
        is-menu-out-of-date?)
    (if (system* download-script (rel-dir ""))
        (run-check (pdf-page (open-pdf (rel-dir "output/menu.pdf")) 0))
        "download.sh completed with errors")
    today)

; raw-menu-lines: List<String>
; List of lines in the menu without leading lines.
(define RAW-MENU-LINES
  (drop 
   (read-lines menu-file)
   2))

; menu: List<List<String>>
; Like raw-menu-lines but without date and trailing lines (edit notice and eof char) 
(define MENU (drop
              (take (rest RAW-MENU-LINES)
                    (- (length RAW-MENU-LINES) 3))
              1))

; ====================
; = HELPER FUNCTIONS =

; price?: String -> Boolean
; Returns true if the given string is a price (fr.)
(define (price? string)
  (string-contains? string "fr."))
; Tests
(check-expect (price? "fr. 10.00") #t)
(check-expect (price? "10.00") #f)

; empty-string? : String -> Boolean
; Returns #true if the given string is empty.
(define (empty-string? string)
  (not (non-empty-string? string)))
; Tests
(check-expect (empty-string? "") #t)
(check-expect (empty-string? "Pasta") #f)

; remove-empty-strings: List<String> -> List<String>
; Removes empty-string elements
(define (remove-empty-strings list)
  (filter non-empty-string? list))
; Test
(check-expect (remove-empty-strings '("" "Pasta" "del" "" "Giorno")) '("Pasta" "del" "Giorno"))

; drop-tail: List<A> -> List<A>
; Removes the last element from the given list.
(define (drop-tail list)
  (take list (sub1 (length list))))
; Test
(check-expect (drop-tail (list 'a 'b 'c)) (list 'a 'b))

; normalise-string-list: List<String> -> List<String>
; Given a List of Strings, replaces all whitespace sequences in each string element with a single space.
; Leading and trailing whitespace is removed.
(define (normalise-string-list list)
  (map string-normalize-spaces list))
; Tests
(check-expect (normalise-string-list '("   ")) '(""))
(check-expect (normalise-string-list '("  Trim  Time  " " Now ")) '("Trim Time" "Now"))

; split-3spaces : String -> List<String>
; Given a String s, returns a list of the substrings separated by 3 spaces in s.
(define (split-3spaces s)
  (regexp-split #rx"   " s))
; Tests
(check-expect (split-3spaces "Hi   There") '("Hi" "There"))
(check-expect (split-3spaces "Hello World   Second   Third") '("Hello World" "Second" "Third"))

; split-2spaces : String -> List<String>
; Given a String s, returns a list of the substrings separated by 2 spaces in s.
(define (split-2spaces s)
  (regexp-split #rx"  " s))
; Tests
(check-expect (split-2spaces "Pasta  Pizza  Carne") '("Pasta" "Pizza" "Carne"))
(check-expect (split-2spaces "Pasta  Pizza Carne") '("Pasta" "Pizza Carne"))

; split-0spaces : String -> List<String>
; Given a String s, returns a list of the capitalised substrings separated by 0 spaces in s.
(define (split-0spaces s)
  (if (regexp-match? #rx"[a-z][A-Z]" s)
      (split-2spaces (list->string
                      (insert-at-list (flatten
                                       (map (lambda (x) (cons (add1 (car x)) (cdr x)))
                                            (regexp-match-positions #rx"[a-z][A-Z]" s)))
                                      #\space
                                      (string->list s))))
      s))
; Tests
(check-expect (split-0spaces "PastaPizza Diavola") '("Pasta" "Pizza Diavola"))
(check-expect (split-0spaces "Pasta PizzaDiavola") '("Pasta Pizza" "Diavola"))

; get-indexes: List<A> A Number -> List<Number>
; Returns the indexes [0, length - 1]  of the occurrences of the given element in the list.
(define (get-indexes list element index)
  (cond [(empty? list) '()]
        [(equal? (first list) element) (cons index (get-indexes (rest list) element (add1 index)))]
        [else (get-indexes (rest list) element (add1 index))]))
; Tests
(check-expect (get-indexes (list 'a 'b 'a 'b) 'a 0) (list 0 2))
(check-expect (get-indexes (list 'a 'b 'c 'z 'ca 'c) 'c 0) (list 2 5))

; insert-at: Number A List<A> -> List<A>
; Adds the given element to the list at the given index
(define (insert-at index element list)
  (cond [(empty? list) (if (zero? index)
                           (cons element list)
                           '())]
        [(zero? index) (cons element list)]
        [else (cons (first list)
                    (insert-at (sub1 index) element (rest list)))]))
; Tests
(check-expect (insert-at 1 'b (list 'a)) (list 'a 'b))
(check-expect (insert-at 0 'b (list 'a)) (list 'b 'a))

; insert-at-list: List<Number> A List<A> -> List<A>
; Adds the given element to the given list at the given indexes
(define (insert-at-list indexes element list)
  (cond [(empty? indexes) list]
        [else (insert-at-list (rest indexes)
                              element
                              (insert-at (first indexes) element list))]))
; Tests
(check-expect (insert-at-list (list 0 1 3) 'b (list 'a 'b)) (list 'b 'b 'a 'b 'b))
(check-expect (insert-at-list (list 0 1 3 4) 'c (list 'a 'a)) (list 'c 'c 'a 'c 'c 'a))

; insert-at*: Number A List<A> -> List<A>
; Like insert-at, but adds the given element only if not already present.
(define (insert-at* index element list)
  (cond [(empty? list) (if (zero? index)
                           (cons element list)
                           '())]
        [(and (zero? index)
              (not (equal? element (first list))))
         (cons element list)]
        [else (cons (first list)
                    (insert-at* (sub1 index) element (rest list)))]))
; Tests
(check-expect (insert-at* 1 'b (list 'a)) (list 'a 'b))
(check-expect (insert-at* 1 'b (list 'a 'b)) (list 'a 'b))

; insert-at-list*: List<Number> A List<A> -> List<A>
; Like insert-at-list, but adds the given element only if not already present.
(define (insert-at-list* indexes element list)
  (cond [(empty? indexes) list]
        [else (insert-at-list* (rest indexes)
                               element
                               (insert-at* (first indexes) element list))]))
; Tests
(check-expect (insert-at-list* (list 0 1 3) 'b (list 'a 'b)) (list 'b 'b 'a 'b))
(check-expect (insert-at-list* (list 0 1) 'c (list 'c 'b)) (list 'c 'c 'b))

; consistent-whitespace: List<A> List<A> -> List<A>
; Adds whitespace to the given to-list at the same indexes as the given from-list.
(define (consistent-whitespace from-list to-list)
  (insert-at-list* (get-indexes from-list "" 0) "" to-list))
; Test
(check-expect (consistent-whitespace (list "" "Pasta" "" "Pizza")
                                     (list "Pasta" "Pizza"))
              (list "" "Pasta" "" "Pizza"))

; take-firsts: List<List<A>> -> List<A>
; Returns the first elements of each list in the given list of lists.
(define (take-firsts lists)
  (foldr (lambda (element rest-lists) (cons (first element) rest-lists)) '() lists))
; Tests
(check-expect (take-firsts (list '('a 'b) '(1 2))) '('a 1))
(check-expect (take-firsts (list '('c 'b 'd) '(2 3))) '('c 2))

; drop-firsts: List<List<A>> -> List<List<A>>
; Removes the first elements of each list in the given list of lists
(define (drop-firsts lists)
  (map (lambda (x) (drop x 1)) lists))
; Test
(check-expect (drop-firsts (list '('a 'b 'c) '(1 2 3))) (list '('b 'c) '(2 3)))

; ===================
; = MENU DATA MANIP =

; day-menu is a struct with:
; - full-course: List<String>
; - single-course: List<String>
; - vegetarian-course: List<String>
(struct day-menu (full single veggie))

; append-dish: DayMenu FoodType String -> DayMenu
; Adds the given dish (String) to the List<String> of the given FoodType.
; FoodType is one of "full", "single", "veggie"
(define (append-dish day type dish)
  (cond [(or (price? dish)
             (empty-string? dish)) day]
        [(string=? type "full") (day-menu (append (day-menu-full day) (list dish))
                                          (day-menu-single day)
                                          (day-menu-veggie day))]
        [(string=? type "single") (day-menu (day-menu-full day)
                                            (append (day-menu-single day) (list dish))
                                            (day-menu-veggie day))]
        [(string=? type "veggie") (day-menu (day-menu-full day)
                                            (day-menu-single day)
                                            (append (day-menu-veggie day) (list dish)))]))
; Test
(check-expect (day-menu-full (append-dish (day-menu (list "Pasta") '() '())
                                          "full"
                                          "Pizza")) (list "Pasta" "Pizza"))

; update-week: List<DayMenu> FoodType List<String>
; Adds each element of the given menu-line to the corresponding day-menu
(define (update-week day-list food-type menu-line)
  (cond [(or (empty? menu-line)
             (empty? day-list)) '()]
        [else (cons (append-dish (first day-list)
                                 food-type
                                 (first menu-line))
                    (update-week (rest day-list)
                                 food-type
                                 (rest menu-line)))]))

; add-blanks: List<List<String>> List<List<String>> -> List<List<String>>
; If a menu line has less than 5 elements (i.e. at least one day has no food),
; add whitespace into the menu line according to the corresponding check-list whitespace
(define (add-blanks menu-lines check-lists)
  (cond [(empty? menu-lines) '()]
        [(< (length (first menu-lines)) 5)
         (cons (consistent-whitespace (take-firsts check-lists) (first menu-lines))
               (add-blanks (rest menu-lines) (drop-firsts check-lists)))]
        [else (cons (first menu-lines) (add-blanks (rest menu-lines) (drop-firsts check-lists)))]))

; map-menu: [ List<String> -> List<String> ] List<List<String>> -> List<List<String>>
; Applies given function to each element of the given menu.
(define (map-menu fn menu-lines)
  (cond [(empty? menu-lines) '()]
        [(< (length (first menu-lines)) 5)
         (cons (flatten
                (map (lambda (x) (fn x)) (first menu-lines)))
               (map-menu fn (rest menu-lines)))]
        [else (cons (first menu-lines) (map-menu fn (rest menu-lines)))]))
; Tests
(check-expect (map-menu split-2spaces (list '("Pasta  Panna" "Sugo  Pizza" "Other stuff")
                                            '("Pasta" "Panna" "Sugo  Pizza" "Other stuff")))
              (list '("Pasta" "Panna" "Sugo" "Pizza" "Other stuff")
                    '("Pasta" "Panna" "Sugo" "Pizza" "Other stuff")))
(check-expect (map-menu split-0spaces (list '("PastaPanna" "SugoPizza" "Other stuff")
                                            '("Pasta" "Panna" "SugoPizza" "Other stuff")))
              (list '("Pasta" "Panna" "Sugo" "Pizza" "Other stuff")
                    '("Pasta" "Panna" "Sugo" "Pizza" "Other stuff")))

; split-exception-handler: List<String> -> List<String>
; Makes sure there is a food entry for each day
(define (split-exception-handler menu-lines)
  (local (
          ; check-week: List<List<String>>
          ; Needed for assigning food in a menu line to the correct day
          (define check-week
            (local (; make-check-consistent: List<String>
                    ; Adds whitespace to the given list based on menu
                    (define (consistent-check-whitespace day-check)
                      (consistent-whitespace MENU day-check)))
              ; Reads check-files and makes format consistent with the MENU
              (map (lambda (day)
                     (consistent-check-whitespace (drop-tail day)))
                   (list (read-lines (rel-dir "output/mon.txt"))
                         (read-lines (rel-dir "output/tue.txt"))
                         (read-lines (rel-dir "output/wed.txt"))
                         (read-lines (rel-dir "output/thu.txt"))
                         (read-lines (rel-dir "output/fri.txt")))))))
    ; Fill in empty food, split 2-spaces, split no-spaces
    (map-menu split-0spaces
              (map-menu split-2spaces
                        (add-blanks menu-lines check-week)))))

; split-into-days: DayMenu FoodType List<List<String>> -> DayMenu
; Adds each menu entry to the correct day and food-type in the given DayMenu
(define (split-into-days day-list food-type parsed-lines)
  (local (; first*: List<List<A>> -> A
          (define (first* lists)
            (first (first lists))))
    ; Go through each parsed-line
    (cond [(empty? parsed-lines) day-list]
          ; 'update' food-type
          [(string-ci=? (first* parsed-lines) "piatto del giorno")
           (split-into-days day-list "full" (rest parsed-lines))]
          [(string-ci=? (first* parsed-lines) "pasta del giorno")
           (split-into-days day-list "single" (rest parsed-lines))]
          [(string-ci=? (first* parsed-lines) "piatto vegetariano")
           (split-into-days day-list "veggie" (rest parsed-lines))]
          ; Add current line to the DayMenu and go on with the rest of the menu lines
          [else (split-into-days
                 (update-week day-list food-type (first parsed-lines))
                 food-type
                 (rest parsed-lines))])))

; PARSED-MENU: List<List<String>>
; List of lines in the menu with split food elements 
(define PARSED-MENU
  (split-exception-handler
   (map normalise-string-list
        (map remove-empty-strings
             (map split-3spaces MENU)))))

; =============================
; = PARSING RESULTS (at last) = 
; List<DayMenu>

; menu-date: String
; "Settimana dal dd.mm.yyyy al dd.mm.yyyy" is parsed which then becomes "dd.mm.yyyy - dd.mm.yyyy".
(define MENU-DATE (string-replace
                   (string-join
                    (drop (remove-empty-strings (regexp-split #rx" " (first RAW-MENU-LINES))) 2)
                    " ")
                   "al" "-"))

(define menu-ready
  (split-into-days (list (day-menu '() '() '())
                         (day-menu '() '() '())
                         (day-menu '() '() '())
                         (day-menu '() '() '())
                         (day-menu '() '() '()))
                   "full"
                   PARSED-MENU))

; List<DayMenu-full>
; List of the week's full-courses
(define full-courses
  (map (lambda (x) (day-menu-full x)) menu-ready))

; List<DayMenu-single>
; List of the week's single-courses
(define single-courses
  (map (lambda (x) (day-menu-single x)) menu-ready))

; List<DayMenu-veggie>
; List of the week's vegetarian-courses
(define veggie-courses
  (map (lambda (x) (day-menu-veggie x)) menu-ready))

; =========================
; = MENU CACHE AND RETURN =

; Write a txt file containing the week starting and ending date.
(write-file (rel-dir "menus/timespan.txt") MENU-DATE)

; write-files : List<String> String
; Writes a txt file containing the full course for each day of the week.
; The name of the txt file is in the following format: 'day-postfix.txt'
(define (write-files menu postfix)
  (for ([i (in-range 0 5)]
        [day menu])
       (cond [(= i 0) (write-file (rel-dir (string-append "menus/mon-" postfix ".txt")) (string-join day "\n"))]
             [(= i 1) (write-file (rel-dir (string-append "menus/tue-" postfix ".txt")) (string-join day "\n"))]
             [(= i 2) (write-file (rel-dir (string-append "menus/wed-" postfix ".txt")) (string-join day "\n"))]
             [(= i 3) (write-file (rel-dir (string-append "menus/thu-" postfix ".txt")) (string-join day "\n"))]
             [(= i 4) (write-file (rel-dir (string-append "menus/fri-" postfix ".txt")) (string-join day "\n"))])))

; A Day is one of:
; - 'Monday
; - 'Tuesday
; - 'Wednesday
; - 'Thursday
; - 'Friday
; - 'NotAvailable
; Interpretation: A day of the working week or not available if the canteen isn't open or the current is Saturday or Sunday.

; menu-for-day : Day -> DayMenu
; Returns the full menu for the given day if already cached. If not,
; it is parsed and created and then returned.
(define (menu-for-day day)
  (if (file-exists? (rel-dir "menus/mon-full.txt"))
      (cond [(and (file-exists? (rel-dir "menus/mon-full.txt"))
                  (equal? day 1))
             (day-menu 
              (read-lines (rel-dir "menus/mon-full.txt"))
              (read-lines (rel-dir "menus/mon-single.txt"))
              (read-lines (rel-dir "menus/mon-veggie.txt")))]
            [(and (file-exists? (rel-dir "menus/tue-full.txt"))
                  (equal? day 2))
             (day-menu
              (read-lines (rel-dir "menus/tue-full.txt"))
              (read-lines (rel-dir "menus/tue-single.txt"))
              (read-lines (rel-dir "menus/tue-veggie.txt")))]
            [(and (file-exists? (rel-dir "menus/wed-full.txt"))
                  (equal? day 3))
             (day-menu
              (read-lines (rel-dir "menus/wed-full.txt"))
              (read-lines (rel-dir "menus/wed-single.txt"))
              (read-lines (rel-dir "menus/wed-veggie.txt")))]
            [(and (file-exists? (rel-dir "menus/thu-full.txt"))
                  (equal? day 4))
             (day-menu
              (read-lines (rel-dir "menus/thu-full.txt"))
              (read-lines (rel-dir "menus/thu-single.txt"))
              (read-lines (rel-dir "menus/thu-veggie.txt")))]
            [(and (file-exists? (rel-dir "menus/fri-full.txt"))
                  (equal? day 5))
             (day-menu
              (read-lines (rel-dir "menus/fri-full.txt"))
              (read-lines (rel-dir "menus/fri-single.txt"))
              (read-lines (rel-dir "menus/fri-veggie.txt")))]
            [else (day-menu '("Menu not available today. 😭")
                            '("Menu not available today. 😭")
                            '("Menu not available today. 😭"))])
      ; If there is no cached menu, generate and return it.
      (begin (write-files full-courses "full")
             (write-files single-courses "single")
             (write-files veggie-courses "veggie")
             (menu-for-day day))))
; Tests
(check-satisfied (menu-for-day 1) day-menu?)
(check-satisfied (menu-for-day 2) day-menu?)
(check-satisfied (menu-for-day 3) day-menu?)
(check-satisfied (menu-for-day 4) day-menu?)
(check-satisfied (menu-for-day 5) day-menu?)
(check-satisfied (menu-for-day 0) day-menu?)

; Run check-expects
(test)