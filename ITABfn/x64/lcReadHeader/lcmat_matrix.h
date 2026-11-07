// lcmat_matrix.h: interface for the lcMat_Matrix class.
//
//
//    The matrix is made by row-vectors
//
//    rows:    number of vectors
//    columns: number of vector's elements
//
//////////////////////////////////////////////////////////////////////

#ifndef LCMAT_MATRIX
#define LCMAT_MATRIX


#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000

#include "lcmat_basevector.h"
#include <stdio.h>

template <class T> class lcMat_Matrix 
{
public:
   lcMat_Matrix() { rows = 0; columns = 0; matrix = NULL; p= NULL; }
   lcMat_Matrix(int r,int c) {  matrix = new lcMat_BaseVector<T>[r];
                                          for(int i=0;i<r;i++) matrix[i].setSize(c);
                                          rows = r; columns = c; p= NULL;}

   bool save(char *fname){ return true;};
   bool save(FILE* fp){
		fwrite((char*)&rows,sizeof(int),1,fp);
		fwrite((char*)&columns,sizeof(int),1,fp);
		if (matrix!=NULL) for(int i=0;i<rows;i++) matrix[i].save(fp);
		return true;
   };

   void setValue(int r, int c, T value){
		matrix[r].setValue(c,value);
   }

   bool load(char *fname){ return true; };
   bool load(FILE* fp){
		if(((rows!=0)||(columns!=0))&&(matrix!=NULL)) delete[] matrix;
		if(p!=NULL) delete[] p;
		p = NULL;
		matrix = NULL;
		fread((char*)&rows,sizeof(int),1,fp);
		fread((char*)&columns,sizeof(int),1,fp);
		if(rows>0){
			matrix = new lcMat_BaseVector<T>[rows];
			for(int i=0;i<rows;i++) matrix[i].load(fp);
		}
	   return true;
   };

   int getRows(){ return rows;}
   int getColumns(){ return columns;}

   bool isEmpty(){
	   if(!(rows+columns)) return true;
	   else return false;
   }

   virtual ~lcMat_Matrix() { 
      reset();
   }

   void reset(){
      if((rows!=0)||(columns!=0)) delete[] matrix;  
	  matrix = NULL;
      if (p!=NULL) delete[] p; 
      p = NULL;
	  rows = 0;
	  columns=0;
   }

   lcMat_BaseVector<int> size() { lcMat_BaseVector<int> dims(2); dims[0] = rows; dims[1] = columns; return dims;}

   const lcMat_BaseVector<T>& operator[](int column) const { if (((column)>0)||((column)<nelem)) return matrix[column]; return *matrix; }
   lcMat_BaseVector<T>& operator[](int column) { return matrix[column]; }

   void transpose() { int i;
      lcMat_BaseVector<T> *temp;
      temp = new lcMat_BaseVector<T>[columns]; 
      for(i=0;i<columns;i++) temp[i].setSize(rows);
      for(i=0;i<rows;i++) for(int l=0;l<columns;l++) temp[l][i] = matrix[i][l];
      delete[] matrix; matrix = temp; i = rows; rows = columns; columns = i; }

   virtual void fill( T value ) { for(int i=0;i<rows;i++) matrix[i].fill(value); }

   virtual void fill( T **array, int r, int c) { 
      int i,j; if(matrix!=NULL) delete[] matrix;
      matrix = new lcMat_BaseVector<T>[r];
      try{
		for(i=0;i<r;i++) matrix[i].setSize(c);
	  }catch(...){

		j = 0;

	  }
      rows = r; columns = c;
      for(i=0;i<rows;i++) matrix[i].fill(array[i],c); }

   virtual void fill( T *array, int r, int c) { 
      int i; if(matrix!=NULL) delete[] matrix;
      matrix = new lcMat_BaseVector<T>[r];
      for(i=0;i<r;i++) matrix[i].setSize(c);
      rows = r; columns = c;
      for(i=0;i<rows;i++) matrix[i].fill(&(array[i*columns]),c); }

   // copy matrices
   lcMat_Matrix<T>& operator=(lcMat_Matrix<T> &m) { int i; if (this == &m) return *this;
	  if(matrix!=NULL) {
		delete[] matrix;
		matrix = NULL;
	  }
	  if(!m.columns || !m.rows) return *this;
      matrix = new lcMat_BaseVector<T>[m.rows];
      for(i=0;i<m.rows;i++) matrix[i].setSize(m.columns);
      rows = m.rows; columns = m.columns;
      for(i=0;i<m.rows;i++) matrix[i]=m[i]; return *this;}

   // product with a scalar
   lcMat_Matrix<T> operator*(const int scalar) { lcMat_Matrix<T> temp(rows,columns);
      for(int i=0;i<rows;i++) temp[i] = matrix[i]*scalar; return temp;} 
   lcMat_Matrix<T> operator*(const float scalar) { lcMat_Matrix<T> temp(rows,columns);
      for(int i=0;i<rows;i++) temp[i] = matrix[i]*scalar; return temp;} 
   lcMat_Matrix<T> operator*(const double scalar) { lcMat_Matrix<T> temp(rows,columns);
      for(int i=0;i<rows;i++) temp[i] = matrix[i]*scalar; return temp;} 

   // copy constructor
   lcMat_Matrix<T>(lcMat_Matrix<T> &m) { 
      int i; rows = m.rows; columns = m.columns;
      matrix = new lcMat_BaseVector<T>[m.rows];
      for(i=0;i<m.rows;i++) matrix[i].setSize(m.columns);
      for(i=0;i<m.rows;i++) matrix[i] = m[i]; 
      p = m.p;}
/*
   friend ::ostream& operator<< (::ostream& out_data, lcMat_Matrix<T> &m){
      int i,l;
      switch(m.rows) {
      case 0:
         break;
      case 1:
         for (i=0;i<m.columns;i++) 
            out_data << "[" << i << "]=" << m.matrix[0][i] << " ";
         break;
      default:
         for (i=0;i<m.rows;i++) {
            for (l=0;l<m.columns;l++) {
               out_data << "[" << i << "]";
               if (m.columns != 1) cout << "[" << l << "]";
               cout << "=" << m.matrix[i][l] << " ";
            }
            cout << endl;
         }
      }
      
      cout << endl;
      return out_data;
   }
*/

   // sum
   lcMat_Matrix<T> operator+(lcMat_Matrix<int> &m) { lcMat_Matrix<T> temp(rows,columns);
      for(int i=0;i<rows;i++) temp[i] = matrix[i]+m[i]; return temp;}
   lcMat_Matrix<T> operator+(lcMat_Matrix<float> &m) { lcMat_Matrix<T> temp(rows,columns);
      for(int i=0;i<rows;i++) temp[i] = matrix[i]+m[i]; return temp;}
   lcMat_Matrix<T> operator+(lcMat_Matrix<double> &m) { lcMat_Matrix<T> temp(rows,columns);
      for(int i=0;i<rows;i++) temp[i] = matrix[i]+m[i]; return temp;}

   // subtraction
   lcMat_Matrix<T> operator-(lcMat_Matrix<int> &m) { lcMat_Matrix<T> temp(rows,columns);
      for(int i=0;i<rows;i++) temp[i] = matrix[i]-m[i]; return temp;}
   lcMat_Matrix<T> operator-(lcMat_Matrix<float> &m) { lcMat_Matrix<T> temp(rows,columns);
      for(int i=0;i<rows;i++) temp[i] = matrix[i]-m[i]; return temp;}
   lcMat_Matrix<T> operator-(lcMat_Matrix<double> &m) { lcMat_Matrix<T> temp(rows,columns);
      for(int i=0;i<rows;i++) temp[i] = matrix[i]-m[i]; return temp;}

   void identity(){ fill(0); for(int i=0;i<rows;i++) matrix[i][i] = 1;}

   T *pointer(int mode = 0){ 
      // if (p!=NULL) return p; 
      return setPointer(mode); 
   }

   lcMat_BaseVector<T> *pMatrix() { return matrix; }

   void setSize(int r, int c){
      if ((matrix!=NULL)&&((rows>0)||(columns>0))) delete[] matrix;
      matrix = new lcMat_BaseVector<T>[r];
      for(int i=0;i<r;i++) matrix[i].setSize(c);
      rows = r; columns = c; p= NULL;
   }

   T *setPointer(int mode=0){
	   int i,j;
      if (p!=NULL) delete[] p;
      p = new T[rows*columns]; 
      
	  if(!mode)
	      for(i=0; i<rows; i++) 
		     for(j=0; j<columns; j++) 
			    p[i*columns+j] = matrix[i][j]; 
	  else 
		  for(j=0; j<columns; j++) 
			 for(i=0; i<rows; i++) 
				p[j*rows+i] = matrix[i][j]; 
         
      return p; 
   }

   lcMat_Vector<T> diag(){
		lcMat_Vector<T> temp;

		temp.setSize(rows);

		for(int i=0;i<rows; i++) temp[i] = matrix[i][i];

		return temp;

   }

protected:
   lcMat_BaseVector<T> *matrix; 
   
   int rows;
   int columns;

private:
   T* p;

};

#endif // LCMAT_MATRIX
