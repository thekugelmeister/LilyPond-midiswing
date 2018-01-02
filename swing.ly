\version "2.16.2"

% Written by Chris Maden, <URL: http://crism.maden.org/ >.
% Released into the public domain.
% Disclaimer: good enough for me; may not be good enough for you.  See
% the documentation of \sw at the end of this file.

% A CHANGE since the 2.14-compatible (and previous) versions: this is
% now slightly more general, but more importantly, the sense of the
% pair Boolean has changed.  Previously in-pair was #f on the first
% half of a beat, and #t on the second half of a beat.  Now, on-beat
% is #t on the first half of a beat, and #f on the second half.  It
% seemed simpler, plus is was well baked-in before I realized it was
% different.  This won’t affect any uses of \sw, but if you were using
% any of these functions directly, Atheia help you.

% Some constants: durations of an eighth note, a triplet quarter, and
% a triplet eighth.
#(define eighth-length (ly:make-duration 3 0 1 1))
#(define swing-one (ly:make-duration 2 0 2 3))
#(define swing-two (ly:make-duration 3 0 2 3))

% (is-eighth? event)
% Returns #t if event is a LilyPond music object with 'duration equal
% to an eighth note, or if it is an 'EventChord whose first component
% passes this same test.
#(define (is-eighth? event)
   (and (ly:music? event)
        (or (equal? (ly:music-property event 'duration)
                    eighth-length)
            (and (eq? (ly:music-property event 'name)
                      'EventChord)
                 (is-eighth? (car (ly:music-property
                                   event
                                   'elements)))))))

% (swing-eighth straight on-beat)
% Assuming that straight is an event with eighth-note duration, or a
% chord of such events, its duration is altered to a quarter-note
% triplet or an eighth-note triplet, depending on the sense of
% on-beat.
#(define (swing-eighth straight on-beat)
   (let ((new-duration (if on-beat swing-one swing-two))
         (new-music (ly:music-deep-copy straight)))
     (if (eq? (ly:music-property straight 'name) 'EventChord)
         (ly:music-set-property!
          new-music
          'elements
          (map (lambda (n) (swing-eighth n on-beat))
               (ly:music-property straight 'elements)))
         (ly:music-set-property! new-music 'duration new-duration))
     new-music))

% (swing-events straight-list on-beat)
% Builds up a copy of a list.  If any members are believed to be
% eighth-note events, they are altered and the sense of on-beat is
% inverted.  Otherwise, (swing-eighths) is recursively called.
#(define (swing-events straight-list on-beat)
   (if (null? straight-list)
       '()
       (let ((next (car straight-list)))
         (if (is-eighth? next)
             (cons (swing-eighth next on-beat)
                   (swing-events (cdr straight-list) (not on-beat)))
             (cons (swing-eighths next on-beat)
                   (swing-events (cdr straight-list) on-beat))))))

% (swing-eighths straight on-beat)
% Makes a copy of LilyPond music objects.  Mostly, this is a deep
% (identical) copy, but it looks through lists for chords and other
% things with durations, and modifies them accordingly.
#(define (swing-eighths straight on-beat)
   (cond
    ((ly:music? straight)
     (let ((elt (ly:music-property straight 'element))
           (elts (ly:music-property straight 'elements))
           (new-music (ly:music-deep-copy straight)))
       (cond
        ((not (null? elts))
         (ly:music-set-property!
          new-music
          'elements
          (swing-eighths elts on-beat)))
        ((not (null? elt))
         (ly:music-set-property!
          new-music 'element
          (swing-eighths elt on-beat))))
       new-music))
    ((list? straight) (swing-events straight on-beat))
    (#t (ly:music-deep-copy straight))))

% \sw music
% Turns a series of notes into two tagged sequences (tagged 'layout
% and 'midi)
% The 'layout tagged sequence is unaltered.  The 'midi tagged sequence
% has pairs of eighth notes turned into swung triplets.
% This only works if eighth notes are always in beat-wise pairs; this
% means no half-beat anacrucis, no dotted quarters, or other
% often-convenient notations.  Chords are presumed to have identical
% durations of all component notes.
sw = #(define-music-function
        (parser location notes)
        (ly:music?)
        (let ((swing (swing-eighths notes #t)))
          #{
            \tag #'layout { $notes }
            \tag #'midi { $swing }
          #}
          ))
