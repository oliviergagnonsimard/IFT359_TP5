#lang racket
(require "Flots-lib.rkt")
(require "TP5-lib-facturation.rkt")
(require "TP5-lib-charge.rkt")
(provide bill-one)
(provide bill-all)
(provide reorganize)
(provide total-bill-for)
(provide total-bill)
(provide CPU-load-stream)
(provide memory-load-stream)
(provide total-load-stream)
(provide stream-of-smoothed-total-loads)
(provide stream-of-overload-periods)
; ***************** IFT359 / TP5
; ***************** Gagnon-Simard, Olivier (24096336)

(define (cout CPU mem nbTaches) (+ (* 10 CPU) (+ (* 5 mem) nbTaches)))

(define (bill-one stream-of-reports month company)
  (let* ([filtre
          (filter-stream
           (lambda (report)
             (and (equal? (report-company report) company)
                  (equal? (report-month report) month)))
           stream-of-reports)]

        

         [total
          (accumulate-stream
           (lambda (report acc)
             (+ acc (cout (report-CPU report)
                          (report-memory report)
                          1)))
           0
           filtre)]

         [type
          (if (empty-stream? filtre)
              '()
              (report-company-type (head filtre))
              )
          ]
         )

   (if (or (equal? type 'EDUCATION) (equal? type 'OBNL) (equal? type '()))
       (list month company 0)
    (list month company total))

    ))

(define (bill-all stream-of-reports month)
  (map (lambda (x) (bill-one stream-of-reports month x))

   (accumulate-stream
   (lambda (report acc)
     (if (member (report-company report) acc) acc (cons (report-company report) acc))
     )
   '()
   stream-of-reports)
  )
  )


(define (reorganize stream-of-reports) 4)

(define (total-bill stream-of-reports fill-criteria?) 3)

(define (total-bill-for stream-of-reports month) 3)

(define (CPU-load-stream workers-states-stream w-id) 3)

(define (memory-load-stream workers-states-stream w-id) 3)

(define (total-load-stream workers-states-stream w-id) 3)

(define (stream-of-smoothed-total-loads workers-state-stream w-id) 3)

(define (stream-of-overload-periods stream-of-states w-id overload?) 3)



   (equal? (bill-one the-stream-of-reports 'janvier 'Google) '(janvier Google 753))
   (equal? (bill-one the-stream-of-reports 'janvier 'APPLE) '(janvier APPLE 1251))
   (equal? (bill-one the-stream-of-reports 'janvier 'IXIA) '(janvier IXIA 0))
   (equal? (bill-one the-stream-of-reports 'janvier 'UdeS) '(janvier UdeS 0))
   (equal? (bill-one the-stream-of-reports 'janvier 'Microsoft) '(janvier Microsoft 0))
   (equal? (bill-one the-stream-of-reports 'février 'Google) '(février Google 501))
   (equal? (bill-one the-stream-of-reports 'février 'APPLE) '(février APPLE 12501))
   (equal? (bill-one the-stream-of-reports 'février 'IXIA) '(février IXIA 0))
   (equal? (bill-one the-stream-of-reports 'février 'UdeS) '(février UdeS 0))
   (equal? (bill-one the-stream-of-reports 'février 'Microsoft) '(février Microsoft 16251))
   (equal? (bill-one the-stream-of-reports 'mars 'Google) '(mars Google 0))
(bill-all the-stream-of-reports 'janvier)
(bill-all the-stream-of-reports 'février)
(bill-all the-stream-of-reports 'mars)

;(make-task-report 'janvier 'W-1 'ts-1 10 5 'Google 'CORPORATIF)
                              ;(make-task-report 'janvier 'W-2 'ts-2 20 10 'Google 'CORPORATIF)
                              ;(make-task-report 'janvier 'W-3 'ts-3 30 15 'Google 'CORPORATIF)
                              ;(make-task-report 'février 'W-4 'ts-4 40 20 'Google 'CORPORATIF)
                              ;(make-task-report 'janvier 'W-1 'ts-1 200 100 'IXIA 'OBNL)
                              ;(make-task-report 'février 'W-2 'ts-1 2000 1000 'IXIA 'OBNL)
                              ;(make-task-report 'janvier 'W-3 'ts-1 300 150 'UdeS 'EDUCATION)
                              ;(make-task-report 'février 'W-4 'ts-1 3000 150 'UdeS 'EDUCATION)
                              ;(make-task-report 'janvier 'W-1 'ts-1 100 50 'APPLE 'CORPORATIF)
                              ;(make-task-report 'février 'W-2 'ts-1 1000 500 'APPLE 'CORPORATIF)
                              ;(make-task-report 'février 'W-3 'ts-1 1500 250 'Microsoft 'CORPORATIF)

; Month Worker-id Task-id CPU Memory Company CompanyType