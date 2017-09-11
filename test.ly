\version "2.19.49"
\include "beatalign.ly"
\include "swing.ly"

global = {
  \key c \major

  %% Time Signature
  \time 4/4
  \tempo 4=100
}

testmusic = \ba \relative c' {
  |
  % \partial 8 c8 |
  c1 |
  c2 c2 |
  c4 c4 c4 c4 |
  c8 c8 c8 c8 c8 c8 c8 c8 |
  c2. c4 |
  c4. c4. c4 |
  c4 c4. c4. |
  c8 c4 c4 c4 c8 |
  c2~ c2 |
  c8 c4 c8~ c8 r4. |
  c4 c4 c4 c4 |
}

% {
%   #(with-output-to-file "display.txt"
%     (lambda () #{ \displayMusic { \testmusic } #}))
% }

\score
{
  \keepWithTag #'layout
  \new Staff << \global \testmusic >>
  \layout {}
}

\score
{
  \keepWithTag #'midi
  \new Staff << \global \testmusic >>
  \layout {}
  \midi {}
}
