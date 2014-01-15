#ifndef FOO_H
#define FOO_H

#ifdef FOO_DLL
#define EXPORT __declspec(dllexport)
#else
#define EXPORT __declspec(dllimport)
#endif

extern EXPORT int fooish(void);

#endif

