\version "2.19.49"

#(define quarter-moment (ly:make-moment 1/4))
#(define zero-moment (ly:make-moment 0))


#(define (moment-eq? a b)
  (let ((a-main (ly:moment-main a))
        (b-main (ly:moment-main b)))
   (= a-main b-main)))
#(define (moment-leq? a b)
  (or (ly:moment<? a b)
   (moment-eq? a b)))

% WHY DOESN'T THIS WORK???
% #(define (has-duration? event)
%   (and (ly:music? next)
%        (or (ly:music-property next 'duration #f)
%            (and (eq? (ly:music-property event 'name)
%                       'EventChord)
%                 (has-duration? (car (ly:music-property
%                                      event
%                                      'elements)))))))

% (with-output-to-file "display.txt"
% (lambda () #{ \displayMusic { #notes } #}))


#(define (dur-from-mom mom)
  (let ((mom-len (ly:moment-main mom))
        (dur-len (- (inexact->exact (/ (log (ly:moment-main mom)) (log 2))))))
   (ly:make-duration dur-len)))


#(define (off-shorter original)
  (let ((new-music (ly:music-deep-copy original)))
   new-music)
)

% DOES THIS NEED TO TAKE CHORDS INTO ACCOUNT?
#(define (off-longer original partial remaining)
  (let* ((new-partial (ly:music-deep-copy original))
         (new-remaining (ly:music-deep-copy original))
         (new-music (list new-partial new-remaining))
         (new-partial-articulations (ly:music-property new-partial 'articulations '())))
   (ly:music-set-property! new-partial 'duration (dur-from-mom partial))
   (if (not (eq? (ly:music-property new-partial 'name)
                 'RestEvent))
    (ly:music-set-property! new-partial 'articulations (cons (make-music 'TieEvent) new-partial-articulations)))
   (ly:music-set-property! new-remaining 'duration (dur-from-mom remaining))
   new-music)
)

#(define (on-on original)
  (let ((new-music (ly:music-deep-copy original)))
   new-music)
)

#(define (on-off-longer original original-mom next-pos)
  (let* ((new-one (ly:music-deep-copy original))
         (new-two (ly:music-deep-copy original))
         (new-music (list new-one new-two))
         (one-mom (ly:moment-sub original-mom next-pos))
         (new-one-articulations (ly:music-property new-one 'articulations '())))
   (ly:music-set-property! new-one 'duration (dur-from-mom one-mom))
   (if (not (eq? (ly:music-property new-one 'name)
                 'RestEvent))
    (ly:music-set-property! new-one 'articulations (cons (make-music 'TieEvent) new-one-articulations)))
   (ly:music-set-property! new-two 'duration (dur-from-mom next-pos))
   new-music)
)

#(define (on-off-shorter original)
  (let ((new-music (ly:music-deep-copy original)))
   new-music)
)


#(define (music-events original-list beat-pos)
  (if (null? original-list)
   '()
   (let ((next (car original-list))
         (rest (cdr original-list)))
    (if (and (ly:music? next)
             (ly:music-property next 'duration #f))
     (let* ((next-dur (ly:music-property next 'duration))
            (next-mom (ly:duration-length next-dur))
            (next-pos (ly:moment-mod (ly:moment-add beat-pos next-mom)
                                     quarter-moment)))
      (if (not (moment-eq? beat-pos zero-moment))
       (if (moment-leq? (ly:moment-add beat-pos next-mom) quarter-moment)
           (cons (off-shorter next)
                 (music-events rest next-pos))
           (let* ((partial (ly:moment-sub quarter-moment beat-pos))
                  (remaining (ly:moment-sub next-mom partial)))
            (append (off-longer next partial remaining)
                    (music-events rest next-pos)))
      )
       (if (moment-eq? next-pos zero-moment)
           (cons (on-on next)
                 (music-events rest next-pos))
           (if (moment-leq? quarter-moment next-mom)
               (append (on-off-longer next next-mom next-pos)
                       (music-events rest next-pos))
               (cons (on-off-shorter next)
                     (music-events rest next-pos))
               ))
     ))
     (cons
      (beat-align next beat-pos)
      (music-events rest beat-pos))
   )
  )
 )
)


#(define (beat-align original beat-pos)
  (cond
   ((ly:music? original)
    (let ((elt (ly:music-property original 'element))
          (elts (ly:music-property original 'elements))
          (new-music (ly:music-deep-copy original)))
     (cond
      ((not (null? elts))
       (ly:music-set-property!
        new-music
        'elements
        (beat-align elts beat-pos)))
      ((not (null? elt))
       (ly:music-set-property!
        new-music 'element
        (beat-align elt beat-pos))))
     new-music))
   ((list? original)
    (music-events original beat-pos))
   (#t
    (ly:music-deep-copy original))))


ba = #(define-music-function
       (parser location notes)
       (ly:music?)
       (let ((aligned (beat-align notes zero-moment)))
        #{
        \tag #'layout { $notes }
        \tag #'midi { $aligned }
        #}
      )
     )