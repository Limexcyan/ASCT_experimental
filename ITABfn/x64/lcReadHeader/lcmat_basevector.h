// lcmat_basevector.h: interface for the lcMat_BaseVector class.
//
//////////////////////////////////////////////////////////////////////

#ifndef LCMAT_BASEVECTOR
#define LCMAT_BASEVECTOR


#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000

//#include <iostream.h>
#include <math.h>
#include <string.h>
#include <stdio.h>

template <class T> class lcMat_Vector;

template <class T> class lcMat_BaseVector 
{

public:
   // public constructors
   lcMat_BaseVector(){ vector = NULL; nelem = 0; localArray = false; };
   lcMat_BaseVector(int nelements) { vector = new T[nelements]; nelem = nelements; localArray = true;
                                 for(int i=0;i<nelem;i++) vector[i] = 0;}
   // destructor
   virtual ~lcMat_BaseVector() { 
	   if((nelem!=0)&&(vector!=NULL)&&localArray) 
		   delete[] vector; 
	   nelem = 0; }

   // reference
   const T& operator[](int index) const { if (((index)>0)||((index)<nelem)) return *(vector+index); return *vector; }
   T& operator[](int index) { T dummy; if(vector!=NULL) return *(vector+index);else return (dummy=0); }
   
   // resize
   void setSize(int nelements) { if (((vector!=NULL))&&(nelem>0)) delete[] vector; 
                                 vector = new T[nelements]; nelem = nelements; localArray = true;
                                 memset(vector,0,nelements*sizeof(T));                                 
                                 //for(int i=0;i<nelem;i++) vector[i] = 0;
                                 }

   int size() { return nelem; }

   void setValue(int index, T value){ vector[index] = value; }	

	// DISK storing managment
   bool save(char *fname){ return true };
   bool save(FILE* fp){
		fwrite((char*)&nelem,sizeof(int),1,fp);
		if ((nelem>0)&&(vector!=NULL)) fwrite((char*)vector,nelem*sizeof(T),1,fp);
		return true;
   };

   bool load(char *fname){return true;};
   bool load(FILE* fp){
		if((nelem!=0)&&(vector!=NULL)&&localArray) delete[] vector;
		vector = NULL;
		fread((char*)&nelem,sizeof(int),1,fp);
		if(nelem>0){
			vector = new T[nelem];
			fread((char*)vector,nelem*sizeof(T),1,fp);
		}
		localArray = true;
		return true;
   };

   
   // fill
   void fill( T *array, int nelements) { setSize(nelements); for (int i=0;i<nelements;i++) vector[i] = array[i]; localArray = true; }

   void fill( T value ) { for(int i=0;i<nelem;i++) vector[i] = value; }

   // copy vectors
   lcMat_BaseVector<T>& operator=(lcMat_BaseVector<T> &v) { if (this == &v) return *this;
      if ((nelem>0)&&localArray) delete[] vector;
      vector = new T[v.nelem]; nelem = v.nelem; localArray = true;                           
      memset(vector,0,nelem*sizeof(T));                                 
      //for(int i=0;i<nelem;i++) 
      //   vector[i] = v[i]; 
      memcpy(vector,v.vector,sizeof(T)*nelem);
      return *this;  }

   lcMat_BaseVector<T>& operator=(lcMat_Vector<T> &v) { if ((nelem>0)&&localArray) delete[] vector;
      nelem = v.size(); vector = new T[nelem]; localArray = true;                           
      memset(vector,0,nelem*sizeof(T));                                 
      //for(int i=0;i<nelem;i++) 
      //   vector[i] = v[i]; 
      memcpy(vector,v.pointer(),sizeof(T)*nelem);
      return *this;  }

   // product with a scalar
   lcMat_BaseVector<T> operator*(const int &scalar) { lcMat_BaseVector<T> temp(nelem);
      for(int i=0;i<nelem;i++) temp[i] = vector[i]*scalar; return temp;}
   lcMat_BaseVector<T> operator*(const float &scalar) { lcMat_BaseVector<T> temp(nelem);
      for(int i=0;i<nelem;i++) temp[i] = vector[i]*scalar; return temp;}
   lcMat_BaseVector<T> operator*(const double &scalar) { lcMat_BaseVector<T> temp(nelem);
      for(int i=0;i<nelem;i++) temp[i] = vector[i]*scalar; return temp;}

   // sum
   lcMat_BaseVector<T> operator+(lcMat_BaseVector<int> &v) { if (v.nelem!=nelem) return *this;
      lcMat_BaseVector<T> temp(nelem);
      for(int i=0;i<nelem;i++) temp[i] = vector[i]+v[i]; return temp;}
   lcMat_BaseVector<T> operator+(lcMat_BaseVector<float> &v) { if (v.nelem!=nelem) return *this;
      lcMat_BaseVector<T> temp(nelem);
      for(int i=0;i<nelem;i++) temp[i] = vector[i]+v[i]; return temp;}
   lcMat_BaseVector<T> operator+(lcMat_BaseVector<double> &v) { if (v.nelem!=nelem) return *this;
      lcMat_BaseVector<T> temp(nelem);
      for(int i=0;i<nelem;i++) temp[i] = vector[i]+v[i]; return temp;}

   lcMat_BaseVector<T> operator+(lcMat_Vector<int> &v) { if (v.size()!=nelem) return *this;
      lcMat_BaseVector<T> temp(nelem);
      for(int i=0;i<nelem;i++) temp[i] = vector[i]+v[i]; return temp;}
   lcMat_BaseVector<T> operator+(lcMat_Vector<float> &v) { if (v.size()!=nelem) return *this;
      lcMat_BaseVector<T> temp(nelem);
      for(int i=0;i<nelem;i++) temp[i] = vector[i]+v[i]; return temp;}
   lcMat_BaseVector<T> operator+(lcMat_Vector<double> &v) { if (v.size()!=nelem) return *this;
      lcMat_BaseVector<T> temp(nelem);
      for(int i=0;i<nelem;i++) temp[i] = vector[i]+v[i]; return temp;}

   // subtraction
   lcMat_BaseVector<T> operator-(lcMat_BaseVector<int> &v) { if (v.nelem!=nelem) return *this;
      lcMat_BaseVector<T> temp(nelem);
      for(int i=0;i<nelem;i++) temp[i] = vector[i]-v[i]; return temp;}
   lcMat_BaseVector<T> operator-(lcMat_BaseVector<float> &v) { if (v.nelem!=nelem) return *this;
      lcMat_BaseVector<T> temp(nelem);
      for(int i=0;i<nelem;i++) temp[i] = vector[i]-v[i]; return temp;}
   lcMat_BaseVector<T> operator-(lcMat_BaseVector<double> &v) { if (v.nelem!=nelem) return *this;
      lcMat_BaseVector<T> temp(nelem);
      for(int i=0;i<nelem;i++) temp[i] = vector[i]-v[i]; return temp;}

   lcMat_BaseVector<T> operator-(lcMat_Vector<int> &v) { if (v.size()!=nelem) return *this;
      lcMat_BaseVector<T> temp(nelem);
      for(int i=0;i<nelem;i++) temp[i] = vector[i]-v[i]; return temp;}
   lcMat_BaseVector<T> operator-(lcMat_Vector<float> &v) { if (v.size()!=nelem) return *this;
      lcMat_BaseVector<T> temp(nelem);
      for(int i=0;i<nelem;i++) temp[i] = vector[i]-v[i]; return temp;}
   lcMat_BaseVector<T> operator-(lcMat_Vector<double> &v) { if (v.size()!=nelem) return *this;
      lcMat_BaseVector<T> temp(nelem);
      for(int i=0;i<nelem;i++) temp[i] = vector[i]-v[i]; return temp;}

   // dot product
   T operator*(lcMat_BaseVector<T> &v) { T result=0; if (v.nelem!=nelem) return 0;
      for(int i=0;i<nelem;i++) result += v[i]*vector[i]; return result;}

   T operator*(lcMat_Vector<T> &v) { T result=0; if (v.size()!=nelem) return 0;
      for(int i=0;i<nelem;i++) result += v[i]*vector[i]; return result;}

   // cross product
   lcMat_BaseVector<T> cross(lcMat_BaseVector<T> v) { lcMat_BaseVector<T> temp(nelem); if ((v.nelem!=nelem)&&(nelem!=3)) return temp;
      temp[0] = vector[1]*v[2] - vector[2]*v[1];
      temp[1] = vector[2]*v[0] - vector[0]*v[2];
      temp[2] = vector[0]*v[1] - vector[1]*v[0];
      return temp;}
   
   lcMat_BaseVector<T> cross(lcMat_Vector<T> v) { lcMat_BaseVector<T> temp(nelem); if ((v.size()!=nelem)&&(nelem!=3)) return temp;
      temp[0] = vector[1]*v[2] - vector[2]*v[1];
      temp[1] = vector[2]*v[0] - vector[0]*v[2];
      temp[2] = vector[0]*v[1] - vector[1]*v[0];
      return temp;}

/*
   friend ::ostream& operator<< (::ostream& out_data, lcMat_BaseVector<T> &v){
      for (int i=0;i<v.nelem;i++) out_data << "[" << i << "]=" << v.vector[i] << "   ";
      cout << endl;
      return out_data;
   }
*/

   // copy constructor
   lcMat_BaseVector<T> (const lcMat_BaseVector<T> &v) { 
      nelem = v.nelem;
      vector = new T[v.nelem]; localArray = true;
      for(int i=0;i<nelem;i++) vector[i] = v[i];}

   T mod() { T res=0; for(int i=0;i<nelem;i++) res += vector[i]*vector[i]; return sqrt(res); };

   T *pointer(){ return vector; }

private:
   T *vector; 
   int nelem;
   bool localArray;
   
};

#endif // LCMAT_BASEVECTOR
