// NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE
//
// The macro FRIJA_ADA_MAIN is automatically defined on the GCC
// command line by the Makefile if a source file named frija_cmain.c
// is found in the root of an executable source file folder.
//
// NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE

// Paste together two tokens using ## macro pasting operator.
#define FRIJA_PASTER(x,y)  x ## y

// Due to how the C standard is written the concatenation of two
// values must be done using a two-step process. See section 6.10.3 of
// the C99 standard for further information; section 6.10.3.1 covers
// 'argument substitution' and section 6.10.3.3 covers the '##'
// operator.
#define FRIJA_EVALUATOR(x,y)  FRIJA_PASTER(x,y)

// Expand to (assuming FRIJA_ADA_MAIN is defined as 'Frija_fnord_foo'
// and macro is called as 'FRIJA_ADA_INIT(void)'):
// Frija_fnord_fooinit(void)
#define FRIJA_ADA_INIT(x)  FRIJA_EVALUATOR(FRIJA_ADA_MAIN, init)(x)

// Expand to (assuming FRIJA_ADA_MAIN is defined as 'Frija_fnord_foo'
// and macro is called as 'FRIJA_ADA_FINAL(void)'):
// Frija_fnord_foofinal(void)
#define FRIJA_ADA_FINAL(x)  FRIJA_EVALUATOR(FRIJA_ADA_MAIN, final)(x)
