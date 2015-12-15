#lang racket
(require racket/gui/base
         net/sendurl
         "parser.rkt"
         "date-checker.rkt"
         "preferences.rkt")
; GUI widgets: http://docs.racket-lang.org/gui/Widget_Gallery.html

; Currently selected day of the week
(define selected-day today)

; A DayAction is one of:
; - 'Previous : Select the previous day.
; - 'Following : Select the following day.

; update-user-interface : DayAction
; Update the user interface to reflect the changes done by the user.
(define (update-user-interface action)
  (cond [(and (equal? action 'Previous) (> selected-day 1) (<= selected-day 5))
         (set! selected-day (sub1 selected-day))
         (send current-day set-label (string-selected-date selected-day))
         (send full-course-text set-label (string-join (day-menu-full (menu-for-day selected-day)) "\n"))
         (send single-course-text set-label (string-join (day-menu-single (menu-for-day selected-day)) "\n"))
         (send veggie-text set-label (string-join (day-menu-veggie (menu-for-day selected-day)) "\n"))
         (cond [(= 1 selected-day) (send previous show #f) (send following show #t)]
               [else (send previous show #t) (send following show #t)])]
        [(and (equal? action 'Following) (>= selected-day 1) (< selected-day 5))
         (set! selected-day (add1 selected-day))
         (send current-day set-label (string-selected-date selected-day))
         (send full-course-text set-label (string-join (day-menu-full (menu-for-day selected-day)) "\n"))
         (send single-course-text set-label (string-join (day-menu-single (menu-for-day selected-day)) "\n"))
         (send veggie-text set-label (string-join (day-menu-veggie (menu-for-day selected-day)) "\n"))
         (cond [(= 5 selected-day) (send following show #f) (send previous show #t)]             
               [else (send following show #t) (send previous show #t)])]))

; ===============
; = Main Window =

; Main frame of the application
(define menu
  (new frame%
       [label "λunchtime @ USI"]
       [width 300]
       [height 350]
       [style '(no-resize-border toolbar-button)]))

; Horizontal header panel containing the current date message, the left and arrow buttons.
(define header
  (new horizontal-panel%
       [parent menu]
       [alignment '(center top)]
       [vert-margin 5]))

; Left arrow
(define previous
  (new button%
       [label "←"]
       [parent header]
       [callback (λ (b e)
                   (update-user-interface 'Previous))]))

; Current day string
(define current-day
  (new message%
       [parent header]
       [label (string-selected-date selected-day)]
       [vert-margin 5]
       [auto-resize #t]))

; Right arrow
(define following
  (new button%
       [label "→"]
       [parent header]       
       [callback (λ (b e)
                   (update-user-interface 'Following))]))

; Set specific initial buttons condition if it's a Monday, Friday or weekend.
(if (or (= selected-day 0)
        (= selected-day 6)
        (= 1 selected-day))
    (send previous show #f) (send previous show #t))
(if (or (= selected-day 0)
        (= selected-day 6)
        (= 5 selected-day))
    (send following show #f) (send following show #t))

; Full course group panel
(define full-course
  (new group-box-panel%
       [parent menu]
       [label (cond [(= user-category 0) "Piatto del Giorno | 11.00 .-"]
                    [(= user-category 1) "Piatto del Giorno | 12.50 .-"]
                    [else "Piatto del Giorno | 13.00 .-"])]))

; Full course menu text
(define full-course-text
  (new message%
       [label (string-join (day-menu-full (menu-for-day selected-day)) "\n")]
       [parent full-course]
       [min-width 300]
       [stretchable-width 300]
       [auto-resize #t]))

; Single course group panel
(define single-course
  (new group-box-panel%
       [parent menu]
       [label (cond [(= user-category 0) "Pasta del Giorno | 7.50 .-"]
                    [(= user-category 1) "Pasta del Giorno | 9.00 .-"]
                    [else "Pasta del Giorno | 9.50 .-"])]))

; Single course text
(define single-course-text
  (new message%
       [label (string-join (day-menu-single (menu-for-day selected-day)) "\n")]
       [parent single-course]
       [min-width 300]
       [stretchable-width 300]
       [auto-resize #t]))

; Veggie course panel
(define veggie
  (new group-box-panel%
       [parent menu]
       [label (cond [(= user-category 0) "Piatto Vegetariano | 10.00 .-"]
                    [(= user-category 1) "Piatto Vegetariano | 11.00 .-"]
                    [else "Piatto Vegetariano | 12.00 .-"])]))

; Veggie course text
(define veggie-text
  (new message%
       [label (string-join (day-menu-veggie (menu-for-day selected-day)) "\n")]
       [parent veggie]
       [min-width 300]
       [stretchable-width 300]
       [auto-resize #t]))

; Preferences button that shows a supplementary frame
(new button%
     [label "Preferences"]
     [parent menu]
     [callback (λ (b e)
                 (send preferences show #t))])

; Show the main menu frame
(send menu show #t)

; ======================
; = Preferences Window =

; Preferences frame
(define preferences
  (new frame%
       [label "Preferences"]
       [width 300]
       [height 300]
       [style (list 'no-resize-border 'toolbar-button)]))

; Empty line to give some space
(new message%
     [label ""]
     [parent preferences])

; Top static message to tell user to choose a category
(new message%
     [parent preferences]
     [label "Who are you?"])

; Radio box containing 3 options
(new radio-box%
     [parent preferences]
     [label #f]
     [choices '("Student" "Professor" "Associate")]
     [selection user-category]
     [style '(horizontal vertical-label)]
     [callback (λ (r e)
                 (save-user-category (send r get-selection))
                 (cond [(= (send r get-selection) 0)
                        (send full-course set-label "Piatto del Giorno | 11.00 .-")
                        (send single-course set-label "Pasta del Giorno | 7.50 .-")
                        (send veggie set-label "Piatto Vegetariano | 10.00 .-")]
                       [(= (send r get-selection) 1)                        
                        (send full-course set-label "Piatto del Giorno | 12.50 .-")
                        (send single-course set-label "Pasta del Giorno | 9.00 .-")
                        (send veggie set-label "Piatto Vegetariano | 11.00 .-")]
                       [else
                        (send full-course set-label "Piatto del Giorno | 13.00 .-")
                        (send single-course set-label "Pasta del Giorno | 9.50 .-")
                        (send veggie set-label "Piatto Vegetariano | 12.00 .-")]))])

; Empty line to give some space
(new message%
     [label "\n"]
     [parent preferences])

; =================
; = Notifications =

(new message%
     [label "When would you like to receive notifications?"]
     [parent preferences])

; When not checked, hides time-m/h
(define notifications?
  (new check-box%	 
       [label "Never"]	 
       [parent preferences]
       [value notifications-disabled?]
       [callback (lambda (c e) 
                   (send time-h show (not (send c get-value)))
                   (send time-m show (not (send c get-value)))
                   (disable-notifications (send c get-value)
                                          (send time-h get-selection)
                                          (send time-m get-selection)))]))

; Time sub-panel
(define notifications
  (new horizontal-panel%
       [parent preferences]
       [alignment '(center center)]
       [vert-margin 5]))


; Choice field to choose the notification hours time
(define time-h (new choice%
                    [label "At"]
                    [parent notifications]
                    [selection (if notifications-disabled?
                                   0
                                   (get-plist-hours (open-input-file PLIST-FILE)))]
                    [choices (map (lambda (x) (number->string x)) (build-list 24 values))]
                    [callback (λ (l e)
                                (save-notification-time-h (send l get-selection)))]))

; Choice field to choose the notification minutes time
(define time-m (new choice%
                    [label ":"]
                    [parent notifications]
                    [selection (if notifications-disabled?
                                   0
                                   (get-plist-minutes (open-input-file PLIST-FILE)))]
                    [choices (map (lambda (x) (number->string x)) (build-list 60 values))]
                    [callback (λ (l e)
                                (save-notification-time-m (send l get-selection)))]))

; Hide time choice% if notifications are disabled
; [enabled ...] doesn't seem to work
(send time-h show (not notifications-disabled?))
(send time-m show (not notifications-disabled?))

; Empty line to give some space
(new message%
     [label "\n"]
     [parent preferences])

; =================
; = About Section =

; Developed by text
(new message%
     [label "λunchtime @ USI was developed by"]
     [parent preferences])

; Horizontal developer buttons panel
(define developers
  (new horizontal-panel%
       [parent preferences]
       [alignment '(center center)]))

; Lara's button
(new button%
     [label "Lara Bruseghini"]
     [parent developers]
     [callback (λ (b e)
                 (send-url "http://atelier.inf.unisi.ch/~brusel/" #t))])
; Patrick's button
(new button%
     [label "Patrick Balestra"]
     [parent developers]
     [callback (λ (b e)
                 (send-url "http://www.patrickbalestra.com" #t))])

; Horizontal Github panel
(define github
  (new horizontal-panel%
       [parent preferences]
       [alignment '(center center)]))

; Hack text
(new message%
     [label "Hack the code on"]
     [parent github])

; Github button
(new button%
     [label "Github"]
     [parent github]
     [callback (λ (b e)
                 (send-url "http://www.github.com"))])

