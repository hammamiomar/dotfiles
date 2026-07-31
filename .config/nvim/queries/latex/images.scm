; Overrides snacks.nvim's latex query: render ONLY display math ($$ blocks
; and math environments) as images. Inline $...$ stays as readable source —
; inline image-math scales each expression differently and looks chaotic.

(displayed_equation
  (#set! image.ext "math.tex"))
  @image.content @image

((math_environment
  (#set! image.ext "math.tex"))
  @image.content @image
  (#not-has-ancestor? @image "displayed_equation" "math_environment"))

(graphics_include
  (_ (path) @image.src)
) @image
