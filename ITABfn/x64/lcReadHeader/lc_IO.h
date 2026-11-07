// lc_IO.h: interface for the lc_IO class.
//
//////////////////////////////////////////////////////////////////////

#if !defined(AFX_LC_IO_H__93E80353_5D76_403C_9968_CF9622A1CB24__INCLUDED_)
#define AFX_LC_IO_H__93E80353_5D76_403C_9968_CF9622A1CB24__INCLUDED_

/*
#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000
*/


#include "lcmat_matrix.h"
#include "lc_support.h"
#include "c:\biomag640\libs\Numerical Recipes\Cpp211\cpp\other\nr.h"

class lc_IO  
{
public:
	lc_IO();
	virtual ~lc_IO();

	static void saveBinary(Vec_O_DP v,char *name);
	static void saveBinary(Mat_I_DP m,char *fname);
	static void saveBinary(lcMat_Matrix<double> m,char *fname);
	static void saveBinary(lcMat_Matrix<double> *m,char *fname);
	static void saveBinary(float *m, int r, int c, char *name,int type=0 );
	static void saveBinary(double *m, int r, int c, char *name,int type=0 );
	static void saveBinary(double *m,int x, int r, int c, char *name,int type=0 );
	static void saveBinary(float **m, int r, int c, char *name, int roff = 0, int coff=0 , int type=0 );
	static void saveBinary(double **m, int r, int c, char *name,int roff = 0, int coff=0 ,int type=0);
	static void saveBinary(int *m, int r, int c, char *name,int type=0 );
	static void saveBinary(double ***m, int x, int r, int c, char *name,int xoff=0, int roff = 0, int coff=0 ,int type=0);
	static void saveBinary(int **m, int r, int c, char *name,int roff = 0, int coff=0 ,int type=0 );
	static void saveBinary( lcMat_BaseVector<float> *m, int size, char *name ,int type=0);
	static void saveBinary( lcMat_BaseVector<double> *m, int size, char *name ,int type=0);

	static int loadBinary( float *m, char *name,int type=0,int *size=NULL );
	static int loadBinary( double *m, char *name ,int type=0,int *size=NULL );
	static int loadBinary( double **m, char *name ,int type=0,int *size=NULL );

//	static int loadBinary( double *m, char *name,int type=0,int *size=NULL  );
//	static void saveBinary( lcMat_Matrix<float> *m, int r, int c, char *name ,int type=0);
//	static void saveBinary( lcMat_Matrix<double> *m, int r, int c, char *name,int type=0 );
};

#endif // !defined(AFX_LC_IO_H__93E80353_5D76_403C_9968_CF9622A1CB24__INCLUDED_)
