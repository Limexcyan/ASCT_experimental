// lc_IO.cpp: implementation of the lc_IO class.
//
//////////////////////////////////////////////////////////////////////
#include "lc_IO.h"

//////////////////////////////////////////////////////////////////////
// Construction/Destruction
//////////////////////////////////////////////////////////////////////

lc_IO::lc_IO()
{

}

lc_IO::~lc_IO()
{

}

void lc_IO::saveBinary(Vec_O_DP v,char *name)
{
	int size,i;
	int dims[2];

	dims[0] = v.size();
	dims[1] = 1;
	size = dims[0];

   char *temp = strrchr(name,'.');
   if(temp!=NULL){
		strhigher(temp);
		if (strcmp(temp,".BIN")==0){
			temp[0] = 0;
		}
   }

   char fname[255];
   FILE *fin;

   strcpy(fname,name);
   strcat(fname,".bin");

   fin = fopen(fname,"wb");

   double *m2 = new double[size];
   for (i=0;i<size;i++) m2[i] = v[i];
   fwrite(m2,sizeof(double),size,fin);
   delete[] m2;

   fclose(fin);

   strcpy(fname,name);
   strcat(fname,"_dim.bin");
   fin = fopen(fname,"wb");

   fwrite(dims,sizeof(int),2,fin);

   fclose(fin);


}

void lc_IO::saveBinary(lcMat_Matrix<double> m,char *name)
{
	int r,c,i,j;
	int dims[2];

	dims[0] = m.getRows();
	dims[1] = m.getColumns();
	c= dims[1];
	r= dims[0];

   char *temp = strrchr(name,'.');
   if(temp!=NULL){
		strhigher(temp);
		if (strcmp(temp,".BIN")==0){
			temp[0] = 0;
		}
   }

   char fname[255];
   FILE *fin;

   strcpy(fname,name);
   strcat(fname,".bin");

   fin = fopen(fname,"wb");

   double *m2 = new double[r*c];
   for (i=0;i<r;i++)
      for(j=0;j<c;j++)
         m2[j*r+i] = (m[i])[j];
   fwrite(m2,sizeof(double),r*c,fin);
   delete[] m2;

   fclose(fin);

   strcpy(fname,name);
   strcat(fname,"_dim.bin");
   fin = fopen(fname,"wb");

   fwrite(dims,sizeof(int),2,fin);

   fclose(fin);
}

void lc_IO::saveBinary(lcMat_Matrix<double> *m,char *name)
{
	int r,c,i,j;
	int dims[2];

	dims[0] = m->getRows();
	dims[1] = m->getColumns();
	c= dims[1];
	r= dims[0];

   char *temp = strrchr(name,'.');
   if(temp!=NULL){
		strhigher(temp);
		if (strcmp(temp,".BIN")==0){
			temp[0] = 0;
		}
   }

   char fname[255];
   FILE *fin;

   strcpy(fname,name);
   strcat(fname,".bin");

   fin = fopen(fname,"wb");

   double *m2 = new double[r*c];
   for (i=0;i<r;i++)
      for(j=0;j<c;j++)
         m2[j*r+i] = ((*m)[i])[j];
   fwrite(m2,sizeof(double),r*c,fin);
   delete[] m2;

   fclose(fin);

   strcpy(fname,name);
   strcat(fname,"_dim.bin");
   fin = fopen(fname,"wb");

   fwrite(dims,sizeof(int),2,fin);

   fclose(fin);
}

void lc_IO::saveBinary(Mat_I_DP m,char *name)
{
	int r,c,i,j;
	int dims[2];

	dims[0] = m.nrows();
	dims[1] = m.ncols();
	c= dims[1];
	r= dims[0];

   char *temp = strrchr(name,'.');
   if(temp!=NULL){
		strhigher(temp);
		if (strcmp(temp,".BIN")==0){
			temp[0] = 0;
		}
   }

   char fname[255];
   FILE *fin;

   strcpy(fname,name);
   strcat(fname,".bin");

   fin = fopen(fname,"wb");

   double *m2 = new double[r*c];
   for (i=0;i<r;i++)
      for(j=0;j<c;j++)
         m2[j*r+i] = (m[i])[j];
   fwrite(m2,sizeof(double),r*c,fin);
   delete[] m2;

   fclose(fin);

   strcpy(fname,name);
   strcat(fname,"_dim.bin");
   fin = fopen(fname,"wb");

   fwrite(dims,sizeof(int),2,fin);

   fclose(fin);


}

void lc_IO::saveBinary( int **m, int r, int c, char *name ,int roff,int coff, int type)
{

	double **dummy = new double*[r];
	for(int k=0;k<r;k++) dummy[k] = new double[c];

	for(int i=0; i<r; i++) 
		for(int j=0; j<c; j++) 
			dummy[i][j] = m[i+roff][j+coff];

	saveBinary(dummy,r,c,name,type);

	for(int k=0;k<r;k++) delete[] dummy[k];
	delete[] dummy;
}

void lc_IO::saveBinary( int *m, int r, int c, char *name ,int type)
{
	double *dummy = new double[r*c];

	for(int i=0; i<(r*c); i++) dummy[i] = m[i];

	saveBinary(dummy,r,c,name,type);

	delete[] dummy;
}

void lc_IO::saveBinary( float *m, int r, int c, char *name ,int type)
{
   int dims[2],i,j;
   dims[0] = r;
   dims[1] = c;

   char *temp = strrchr(name,'.');
   if(temp!=NULL){
		strhigher(temp);
		if (strcmp(temp,".BIN")==0){
			temp[0] = 0;
		}
   }


   char fname[255];
   FILE *fin;

   strcpy(fname,name);
   strcat(fname,".bin");

   fin = fopen(fname,"wb");
   if(fin==NULL) return;

   float *m2;
   switch(type){
   case 0: // store for columns
      m2 = new float[r*c];
      for (i=0;i<r;i++)
         for(j=0;j<c;j++)
            m2[j*r+i] = m[i*c+j];
      fwrite(m2,sizeof(float),r*c,fin);
      delete[] m2;

	break;
   default: // store for rows
      fwrite(m,sizeof(float),r*c,fin);
   break;
   }


   fclose(fin);

   strcpy(fname,name);
   strcat(fname,"_dim.bin");
   fin = fopen(fname,"wb");

   fwrite(dims,sizeof(int),2,fin);

   fclose(fin);

}

void lc_IO::saveBinary( float **m, int r, int c, char *name,int roff,int coff ,int type)
{
   char *temp1 = strrchr(name,'.');
   if(temp1!=NULL){
		strhigher(temp1);
		if (strcmp(temp1,".BIN")==0){
			temp1[0] = 0;
		}
   }
   
   int dims[2],i,j,k;
   dims[0] = r;
   dims[1] = c;

   char *temp = strrchr(name,'.');
   if(temp!=NULL){
		strhigher(temp);
		if (strcmp(temp,".BIN")==0){
			temp[0] = 0;
		}
   }


   char fname[255];
   FILE *fin;

   strcpy(fname,name);
   strcat(fname,".bin");

   fin = fopen(fname,"wb");
   float *colarray;

   switch(type){
   case 0: // store for columns
		colarray = new float[r];
		for(j=0;j<c;j++){
			for(i=0;i<r;i++)
				colarray[i] = m[i+roff][j+coff];
			fwrite(colarray,sizeof(float),r,fin);
		}
		delete[] colarray;
	break;
   default: // store for rows
		for(i=0;i<r;i++)
			fwrite(m[i],sizeof(float),c,fin);
   break;
   }


   fclose(fin);

   strcpy(fname,name);
   strcat(fname,"_dim.bin");
   fin = fopen(fname,"wb");

   fwrite(dims,sizeof(int),2,fin);

   fclose(fin);


/*
   temp = (float *)malloc((r*c)*sizeof(float));

   k = 0;
   for (i=0;i<r;i++){
      for(j=0;j<c;j++){
         temp[k] = m[i+roff][j+coff];
         k++;
      }
   }

	saveBinary(temp,r,c,name,type);

   free(temp);
*/
}

void lc_IO::saveBinary( double **m, int r, int c, char *name,int roff,int coff ,int type)
{
    char *temp1 = strrchr(name,'.');
   if(temp1!=NULL){
		strhigher(temp1);
		if (strcmp(temp1,".BIN")==0){
			temp1[0] = 0;
		}
   }
   
   int dims[2],i,j,k;
   dims[0] = r;
   dims[1] = c;

   char *temp = strrchr(name,'.');
   if(temp!=NULL){
		strhigher(temp);
		if (strcmp(temp,".BIN")==0){
			temp[0] = 0;
		}
   }


   char fname[255];
   FILE *fin;

   strcpy(fname,name);
   strcat(fname,".bin");

   fin = fopen(fname,"wb");
   double *colarray;

   switch(type){
   case 0: // store for columns
		colarray = new double[r];
		for(j=0;j<c;j++){
			for(i=0;i<r;i++)
				colarray[i] = m[i+roff][j+coff];
			fwrite(colarray,sizeof(double),r,fin);
		}
		delete[] colarray;
	break;
   default: // store for rows
		for(i=0;i<r;i++)
			fwrite(m[i],sizeof(double),c,fin);
   break;
   }


   fclose(fin);

   strcpy(fname,name);
   strcat(fname,"_dim.bin");
   fin = fopen(fname,"wb");

   fwrite(dims,sizeof(int),2,fin);

   fclose(fin);
}

/*
void lc_IO::saveBinary( double **m, int r, int c, char *name,int roff,int coff ,int type)
{
   double *temp;

   char *temp1 = strrchr(name,'.');
   if(temp1!=NULL){
		strhigher(temp1);
		if (strcmp(temp1,".BIN")==0){
			temp1[0] = 0;
		}
   }
   
   int dims[2],i,j,k;
   dims[0] = r;
   dims[1] = c;

   temp = (double *)malloc((r*c)*sizeof(double));

   k = 0;
   for (i=0;i<r;i++){
      for(j=0;j<c;j++){
         temp[k] = m[i+roff][j+coff];
         k++;
      }
   }

	saveBinary(temp,r,c,name,type);

   free(temp);
}
*/

/*
void fsaveMatrixD( lcMat_Matrix<double> *m, int r, int c, char *name ,int type)
{
   double *temp;

   char *temp1 = strrchr(name,'.');
   if(temp1!=NULL){
		strhigher(temp1);
		if (strcmp(temp1,".BIN")==0){
			temp1[0] = 0;
		}
   }
   
   int dims[2],i,j,k;
   dims[0] = r;
   dims[1] = c;

   temp = (double *)malloc((r*c)*sizeof(double));

   k = 0;
   for (i=0;i<r;i++){
      for(j=0;j<c;j++){
         temp[k] = ((*m)[i])[j];
         k++;
      }
   }

   fsaveMatrixD(temp,r,c,name,type);

   free(temp);
}
*/


/*
void lc_IO::saveBinary( lcMat_BaseVector<double> *m, char *name ,int type)
{
   double *temp;
   
   int dims[2],j,k;
   dims[0] = 1;
   dims[1] = size;

   temp = (double *)malloc(size*sizeof(double));

   k = 0;
      for(j=0;j<size;j++){
         temp[k] = (*m)[j];
         k++;
      }

   fsaveMatrixD(temp,1,size,name,type);

   free(temp);
}

void lc_IO::saveBinary( lcMat_BaseVector<float> *m, char *name ,int type)
{
   float *temp;
   
   int dims[2],j,k;
   dims[0] = 1;
   dims[1] = size;

   temp = (float *)malloc(size*sizeof(float));

   k = 0;
      for(j=0;j<size;j++){
         temp[k] = (*m)[j];
         k++;
      }

   fsaveMatrix1(temp,1,size,name,type);

   free(temp);
}
*/

/*
void fsaveMatrixF( lcMat_Matrix<float> *m, int r, int c, char *name ,int type)
{
   float *temp;

    char *temp1 = strrchr(name,'.');
   if(temp1!=NULL){
		strhigher(temp1);
		if (strcmp(temp1,".BIN")==0){
			temp1[0] = 0;
		}
   }

   int dims[2],i,j,k;
   dims[0] = r;
   dims[1] = c;

   temp = (float *)malloc((r*c)*sizeof(float));

   k = 0;
   for (i=0;i<r;i++){
      for(j=0;j<c;j++){
         temp[k] = ((*m)[i])[j];
         k++;
      }
   }

   fsaveMatrix1(temp,r,c,name,type);

   free(temp);
}
*/

void lc_IO::saveBinary( double *m, int r, int c, char *name ,int type)
{
   int dims[2],i,j;
   dims[0] = r;
   dims[1] = c;

   char *temp = strrchr(name,'.');
   if(temp!=NULL){
		strhigher(temp);
		if (strcmp(temp,".BIN")==0){
			temp[0] = 0;
		}
   }


   char fname[255];
   FILE *fin;

   strcpy(fname,name);
   strcat(fname,".bin");

   fin = fopen(fname,"wb");
   if(fin = NULL) return;

   double *m2;
   switch(type){
   case 0: // store for columns
      m2 = new double[r*c];
      for (i=0;i<r;i++)
         for(j=0;j<c;j++)
            m2[j*r+i] = m[i*c+j];
      fwrite(m2,sizeof(double),r*c,fin);
      delete[] m2;
   break;
   default: // store for rows
      fwrite(m,sizeof(double),r*c,fin);
   break;
   }


   fclose(fin);

   strcpy(fname,name);
   strcat(fname,"_dim.bin");
   fin = fopen(fname,"wb");

   fwrite(dims,sizeof(int),2,fin);

   fclose(fin);

}


int lc_IO::loadBinary( float *m, char *name ,int type, int *size)
{
   int dims[2],i,j;

   char fname[255];
   FILE *fin;

   char *temp = strrchr(name,'.');
   if(temp!=NULL){
		strhigher(temp);
		if (strcmp(temp,".BIN")==0){
			temp[0] = 0;
		}
   }

   // read matrix dimensions
   strcpy(fname,name);
   strcat(fname,"_dim.bin");
   fin = fopen(fname,"rb");

   if (fin==NULL) return -1;

   fread(dims,sizeof(int),2,fin);

   fclose(fin);

   // read matrix elements
   strcpy(fname,name);
   strcat(fname,".bin");

   fin = fopen(fname,"rb");

   if (fin==NULL) return -1;

   float *m2;
   switch(type){
   case 0: // read for columns
      m2 = new float[dims[0]*dims[1]];
      fread(m2,sizeof(float),dims[0]*dims[1],fin);
      for (i=0;i<dims[0];i++)
         for(j=0;j<dims[1];j++)
            m[i*dims[1]+j] = m2[j*dims[0]+i];
      delete[] m2;
   break;
   default: // read for rows
      fread(m,sizeof(float),dims[0]*dims[1],fin);
   break;
   }

   fclose(fin);

   if(size!=NULL) {
		size[0] = dims[0];
		size[1] = dims[1];
   }

   return 0;
}


/*
int lc_IO::loadBinary( double *m, char *name ,int type,int *size)
{
   int dims[2],i,j;

   char fname[255];
   FILE *fin;

   char *temp = strrchr(name,'.');
   if(temp!=NULL){
		strhigher(temp);
		if (strcmp(temp,".BIN")==0){
			temp[0] = 0;
		}
   }

   // read matrix dimensions
   strcpy(fname,name);
   strcat(fname,"_dim.bin");
   fin = fopen(fname,"rb");

   if (fin==NULL) return -1;

   fread(dims,sizeof(int),2,fin);

   fclose(fin);

   // read matrix elements
   strcpy(fname,name);
   strcat(fname,".bin");

   fin = fopen(fname,"rb");

   if (fin==NULL) return -1;

   float *m2;
   switch(type){
   case 0: // read for columns
      m2 = new float[dims[0]*dims[1]];
      fread(m2,sizeof(float),dims[0]*dims[1],fin);
      for (i=0;i<dims[0];i++)
         for(j=0;j<dims[1];j++)
            m[i*dims[1]+j] = m2[j*dims[0]+i];
      delete[] m2;
   break;
   default: // read for rows
      fread(m,sizeof(float),dims[0]*dims[1],fin);
   break;
   }

   fclose(fin);

   if(size!=NULL) {
		size[0] = dims[0];
		size[1] = dims[1];
   }

   return 0;
}
*/


int lc_IO::loadBinary( double *m, char *name ,int type,int *size)
{
   int dims[2],i,j;

   char fname[255];
   FILE *fin;

   char *temp = strrchr(name,'.');
   if(temp!=NULL){
		strhigher(temp);
		if (strcmp(temp,".BIN")==0){
			temp[0] = 0;
		}
   }

   // read matrix dimensions
   strcpy(fname,name);
   strcat(fname,"_dim.bin");
   fin = fopen(fname,"rb");
   if(fin==NULL){
	   strcpy(fname,name);
	   strcat(fname,".dim");
	   fin = fopen(fname,"rb");
   }

   if(fin==NULL) return -1;

   fread(dims,sizeof(int),2,fin);

   fclose(fin);

   if (m!=NULL) {

   // read matrix elements
   strcpy(fname,name);
   strcat(fname,".bin");

   fin = fopen(fname,"rb");

   double *m2;
   switch(type){
   case 0: // read for columns
      m2 = new double[dims[0]*dims[1]];
      fread(m2,sizeof(double),dims[0]*dims[1],fin);
      for (i=0;i<dims[0];i++)
         for(j=0;j<dims[1];j++)
            m[i*dims[1]+j] = m2[j*dims[0]+i];
      delete[] m2;
   break;
   default: // read for rows
      fread(m,sizeof(double),dims[0]*dims[1],fin);
   break;
   }

   fclose(fin);

   }

   if(size!=NULL) {
		size[0] = dims[0];
		size[1] = dims[1];
   }

   return 0;
}

int lc_IO::loadBinary( double **m, char *name ,int type,int *size)
{
   int dims[2],i,j;

   char fname[255];
   FILE *fin;

   char *temp = strrchr(name,'.');
   if(temp!=NULL){
		strhigher(temp);
		if (strcmp(temp,".BIN")==0){
			temp[0] = 0;
		}
   }

   // read matrix dimensions
   strcpy(fname,name);
   strcat(fname,"_dim.bin");
   fin = fopen(fname,"rb");
   if(fin==NULL){
	   strcpy(fname,name);
	   strcat(fname,".dim");
	   fin = fopen(fname,"rb");
   }

   if(fin==NULL) return -1;

   fread(dims,sizeof(int),2,fin);

   fclose(fin);

   if (m!=NULL) {

   // read matrix elements
   strcpy(fname,name);
   strcat(fname,".bin");

   fin = fopen(fname,"rb");

   double *m2;
   switch(type){
   case 0: // read for columns
      m2 = new double[dims[0]];
      for(j=0;j<dims[1];j++){
	      fread(m2,sizeof(double),dims[0],fin);
		  for(i=0;i<dims[0];i++) m[i][j] = m2[i];
	  }
	  delete[] m2;
   break;
   default: // read for rows
	   for(i=0;i<dims[0];i++)
		fread(m[i],sizeof(double),dims[1],fin);
	   
	break;
   }

   fclose(fin);

   }

   if(size!=NULL) {
		size[0] = dims[0];
		size[1] = dims[1];
   }

   return 0;
}



void lc_IO::saveBinary( double ***m, int x, int r, int c, char *name,int xoff , int roff,int coff, int type)
{
   double *temp;

   char *temp1 = strrchr(name,'.');
   if(temp1!=NULL){
		strhigher(temp1);
		if (strcmp(temp1,".BIN")==0){
			temp1[0] = 0;
		}
   }
   
   int dims[3],i,j,k,n;
   dims[0] = x;
   dims[1] = r;
   dims[2] = c;

   temp = (double *)malloc((x*r*c)*sizeof(double));

   k = 0;
   for (n=0;n<x;n++){
	   for (i=0;i<r;i++){
			for(j=0;j<c;j++){
				temp[k] = m[n+xoff][i+roff][j+coff];
				k++;
			}
	   }
   }

	saveBinary(temp,x,r,c,name,type);

   free(temp);
}

void lc_IO::saveBinary( double *m, int x, int r, int c, char *name ,int type)
{
   int dims[3],i,j,n;
   dims[0] = x;
   dims[1] = r;
   dims[2] = c;

   char *temp = strrchr(name,'.');
   if(temp!=NULL){
		strhigher(temp);
		if (strcmp(temp,".BIN")==0){
			temp[0] = 0;
		}
   }


   char fname[255];
   FILE *fin;

   strcpy(fname,name);
   strcat(fname,".bin");

   fin = fopen(fname,"wb");

   double *m2;
   switch(type){
   case 0: // store for columns
      m2 = new double[x*r*c];
      for (n=0;n<x;n++)
		for (i=0;i<r;i++)
			 for(j=0;j<c;j++)
				m2[n*r*c+j*r+i] = m[n*r*c+i*c+j];
      fwrite(m2,sizeof(double),r*c*x,fin);
      delete[] m2;
   break;
   default: // store for rows
      fwrite(m,sizeof(double),r*c*x,fin);
   break;
   }


   fclose(fin);

   strcpy(fname,name);
   strcat(fname,"_dim.bin");
   fin = fopen(fname,"wb");

   fwrite(dims,sizeof(int),3,fin);

   fclose(fin);

}

