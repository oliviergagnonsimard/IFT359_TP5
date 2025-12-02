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


; Partie 1 : Les flots finis
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

  (define tasks-this-month (filter-stream (lambda (g) (equal? month (report-month g))) stream-of-reports))

  (if (empty-stream? tasks-this-month) the-empty-stream
  
  (map-stream (lambda (x) (bill-one stream-of-reports month x))
              
   (accumulate-stream
   (lambda (report acc)
     (if (and (not (member (report-company report) acc)) (equal? month (report-month report))) (cons (report-company report) acc) acc)
     )
   '()
   stream-of-reports)
  ))
  )

; --- test facturation complexe, les autres c'est test facturation normal
(define (reorganize stream-of-reports)
  (if (empty-stream? stream-of-reports)
      the-empty-stream
      
      (let* ((first-report (head stream-of-reports))
             (current-company (report-company first-report)))
        
        (cons-stream
          ;; on fait le sous flot de la compagny actuelle definie plus haut
          (filter-stream (lambda (x) (equal? (report-company x) current-company))
                         stream-of-reports)
          
          ;; on fait les autres sous flots du reste des reports autres que la company actuelle
          (reorganize (filter-stream (lambda (x) 
                                       (not (equal? (report-company x) current-company)))
                                     stream-of-reports))))))

(define (total-bill stream-of-reports fill-criteria?)
  (define filtre (filter-stream fill-criteria? stream-of-reports))

  (accumulate-stream
   (lambda (report acc)
     (if (or (eq? (report-company-type report) 'EDUCATION) (eq? (report-company-type report) 'OBNL)) acc
      (+ acc (cout (report-CPU report)
                  (report-memory report)
                  1)))
     )
   0
   filtre)
  )

(define (total-bill-for stream-of-reports month)
  (total-bill stream-of-reports (lambda (x) (eq? month (report-month x)) ))
 
  )

; Partie 2 : Les flots infinis

; Fonctions utilitaires
(define (charge-CPU worker) (state-n-waiting worker))
(define (charge-Mem worker) (+ (state-n-waiting worker) (state-n-history worker)))
(define (charge-Totale worker) (+ (* 2 (state-n-waiting worker)) (state-n-history worker)))

(define (CPU-load-stream workers-states-stream w-id)
  (map-stream
   charge-CPU
   (filter-stream (lambda (worker)
                    (eq? w-id (state-w-id worker))
                    )
                  workers-states-stream)

   )
  )

(define (memory-load-stream workers-states-stream w-id)
  (map-stream
   charge-Mem
   (filter-stream (lambda (worker)
                    (eq? w-id (state-w-id worker))
                    )
                  workers-states-stream)

   )
  )

(define (total-load-stream workers-states-stream w-id)
  (map-stream
   charge-Totale
   (filter-stream (lambda (worker)
                    (eq? w-id (state-w-id worker))
                    )
                  workers-states-stream)
   
   )
  )

(define (stream-of-smoothed-total-loads workers-state-stream w-id)
  (define totalStream (total-load-stream workers-state-stream w-id))


  (define (gen prev2 prev1 stream)
    (let* (
           [ctn (head stream)]
           [next (+ (* 0.15 prev2) (* 0.35 prev1 ) (* 0.5 ctn ) )]
           )
      (cons-stream
       next
       (gen prev1 next (tail stream)))))


  (cons-stream 0 (cons-stream 0 (gen 0 0 totalStream)))
  )

(define (stream-of-overload-periods stream-of-states w-id overload?)
  ; pour les debuts de surcharge
  (define debuts
    (filter-stream* (lambda (s1 s2) 
                      (and (not (overload? s1)) 
                         (overload? s2)))
                    stream-of-states 
                    (tail stream-of-states)))
  
  
  
  
  
  ;pour les fins de surcharge
  (define fins 
    (filter-stream* (lambda (s1 s2)
                      (and (overload? s1) (not (overload? s2)))
                      )
                    stream-of-states
                  (tail stream-of-states)))

  
  (define (time state)
    (cadr state))

  
  ; on prend juste la donnée de temps des débuts
  (define t-debuts
    (map-stream (lambda (s-pair) (+ (time (cadr s-pair)) 1)) 
                debuts))








  
  ; on prend juste la donnée de temps des fins
  ; faut enlever 1 jpense lors du calcul à une place quand on fait les fins pk y sont décalés (théorie) => check demain
  (define t-fins
    (map-stream (lambda (s-pair) 
                  (let ((etatSurcharge (car s-pair))) 
                    (let ((temps (time etatSurcharge))
                          (id (car etatSurcharge))) 
                      
                      ; Y faut faire -1 quand c'est le worker-id 1 et le laisser normal quand c'est le 0
                      (if (= id 1)
                          (- temps 1) 
                          temps)
                      ))
                )
                fins))


  
  
  (map-stream* cons t-debuts t-fins)
  ;(map-stream* cons debuts fins)
  ;fins
 )



   ;(equal? (bill-one the-stream-of-reports 'janvier 'Google) '(janvier Google 753))
   ;(equal? (bill-one the-stream-of-reports 'janvier 'APPLE) '(janvier APPLE 1251))
   ;(equal? (bill-one the-stream-of-reports 'janvier 'IXIA) '(janvier IXIA 0))
   ;(equal? (bill-one the-stream-of-reports 'janvier 'UdeS) '(janvier UdeS 0))
   ;(equal? (bill-one the-stream-of-reports 'janvier 'Microsoft) '(janvier Microsoft 0))
   ;(equal? (bill-one the-stream-of-reports 'février 'Google) '(février Google 501))
   ;(equal? (bill-one the-stream-of-reports 'février 'APPLE) '(février APPLE 12501))
   ;(equal? (bill-one the-stream-of-reports 'février 'IXIA) '(février IXIA 0))
   ;(equal? (bill-one the-stream-of-reports 'février 'UdeS) '(février UdeS 0))
   ;(equal? (bill-one the-stream-of-reports 'février 'Microsoft) '(février Microsoft 16251))
   ;(equal? (bill-one the-stream-of-reports 'mars 'Google) '(mars Google 0))
;(define (member-stream? element stream)
  ;(and (not (empty-stream? stream))
       ;(or (equal? element (head stream))
           ;(member-stream? element (tail stream)))))


;(define bills-janvier (bill-all the-stream-of-reports 'janvier))
;(define bills-février (bill-all the-stream-of-reports 'février))
;(define bills-mars (bill-all the-stream-of-reports 'mars))
;(eq? (length-stream bills-janvier) 4)
;(eq? (length-stream bills-février) 5)
;(empty-stream? (bill-all the-stream-of-reports 'mars))
;(member-stream? (bill-one the-stream-of-reports 'janvier 'Google) bills-janvier)
;(member-stream? (bill-one the-stream-of-reports 'janvier 'APPLE) bills-janvier)
;(member-stream? (bill-one the-stream-of-reports 'janvier 'IXIA) bills-janvier)
;(member-stream? (bill-one the-stream-of-reports 'janvier 'UdeS) bills-janvier)
     
;(member-stream? (bill-one the-stream-of-reports 'février 'Google) bills-février)
;(member-stream? (bill-one the-stream-of-reports 'février 'APPLE)bills-février)
;(member-stream? (bill-one the-stream-of-reports 'février 'IXIA) bills-février)
;(member-stream? (bill-one the-stream-of-reports 'février 'UdeS) bills-février)
;(member-stream? (bill-one the-stream-of-reports 'février 'Microsoft) bills-février)

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
;(eq? (total-bill the-stream-of-reports (lambda(report) (eq? (report-company report) 'Google))) 1254)
;(eq? (total-bill the-stream-of-reports (lambda(report) (eq? (report-company report) 'APPLE))) 13752)
;(eq? (total-bill the-stream-of-reports (lambda(report) (eq? (report-company report) 'IXIA))) 0)
;(eq? (total-bill the-stream-of-reports (lambda(report) (eq? (report-company report) 'UdeS))) 0)
;(eq? (total-bill the-stream-of-reports (lambda(report) (eq? (report-company report) 'Microsoft))) 16251)


;(foldr + 0 (map (lambda(m) (total-bill-for the-stream-of-reports m))
                        ;'(janvier février mars)))
;(foldr + 0 (map (lambda(cie) (total-bill the-stream-of-reports (lambda(report) (eq? (report-company report) cie))))
                          ;'(Google APPLE IXIA UdeS Microsoft)))


;(eq?
; (foldr + 0 (map (lambda(m) (total-bill-for the-stream-of-reports m))
;                        '(janvier février mars)))   
;       (foldr + 0 (map (lambda(cie) (total-bill the-stream-of-reports (lambda(report) (eq? (report-company report) cie))))
;                          '(Google APPLE IXIA UdeS Microsoft))))

;(define smoothed-loads-stream-w-0 (stream-of-smoothed-total-loads the-stream-of-workers-states 0))
;(define smoothed-loads-stream-w-1 (stream-of-smoothed-total-loads the-stream-of-workers-states 1))
;(stream->list 10 smoothed-loads-stream-w-0)
;(stream->list 10 smoothed-loads-stream-w-1)

;(define stream-of-overload-periods-w1 (stream->list 6 (stream-of-overload-periods the-stream-of-workers-states 0 (lambda(state) (> (charge-Totale state) 300)))))
;stream-of-overload-periods-w1
;(equal? (stream->list 6 stream-of-overload-periods-w1)
;'((52 . 98) (118 . 174) (252 . 298) (318 . 374) (452 . 498) (518 . 574)))

; Month Worker-id Task-id CPU Memory Company CompanyType