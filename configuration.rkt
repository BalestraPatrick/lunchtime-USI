#lang racket
(require racket/system)

; #false if the configuration is set to debug.
; #true if the configuration is set to create executable
; (different execution paths).
(define RELEASE-BUILD #false)

(provide rel-dir
         RELEASE-BUILD)

; rel-dir String -> String
; Decides the correct path of a file based on the release or debug configuration.
; It finds the relative location based on the directory of the execution.
(define (rel-dir file-name)
  (if RELEASE-BUILD
      (string-replace
       (string-append
        (path->string (path-only (find-system-path 'exec-file)))
        file-name)
       (path->string (find-system-path 'home-dir)) "")
      file-name))