/****************************************************************/
/*  ViP library - Transformation functions                      */
/*                                                              */
/*  by Vittorio Pizzella                                        */
/*                                                              */
/*  May 24, 2003 - 14.0.1                                       */
/*  Feb 11, 2007 - 14.1.1      Added vp_polhemus_megasi         */
/*  Jul 14, 2009 - 14.1.2      Improved vp_polhemus_megasi      */
/*  Aug 26, 2009 - 14.1.3      vp_polhemus_megasi takes care of */
/*                             orientation                      */
/*                                                              */
/****************************************************************/

/******************************************************************************/
/*  Library for biomag programs                                               */
/*                                                                            */
/*  vp_vector vp_car2sph    (vp_vector)                  Cartesian --> Spher  */
/*  vp_vector vp_sph2car    (vp_vector)                  Spher. --> Cartesian */
/*  vp_vector vp_Sp2S       (vp_vector, float, float, float,                  */
/*                           float, float, float)        Sp --> S             */
/*  vp_vector vp_S2Sp       (vp_vector, float, float, float,                  */
/*                           float, float, float)        S --> Sp             */
/*  vp_vector vp_rotate     (float, float, vp_vector)    Rotate point         */
/*  vp_vector vp_inrotate   (float, float, vp_vector)    Inverse of vp_rot    */
/*  void      vp_polhemus_megasi (int, position *)       POLH --> MEGASI      */
/*                                                                            */
/*  float     vp_arc        (float, float, float)        Find elliptic arc    */
/*  float     vp_angle      (float, float, float)        Find elliptic angle  */
/*                                                                            */
/*                                                                            */
/*  Old routines (do not use in new code)                                     */
/*  void  vp_kheops_nmr (int, position *)                  KHEOPS --> NMR     */
/*  void  vp_nmr_megasi (int, float, position *, vp_vector *)  NMR --> MEGASI */
/*  void  vp_nmr_dati  (int, ch_position *, vp_vector *)   NMR --> DATI       */
/*  apos  vp_car_sph   (xpos)                         Cartesian --> Spher.    */
/*  xpos  vp_sph_car   (apos)                         Spher. --> Cartesian    */
/*  apos  vp_rot       (float, float, apos)           Rotate point            */
/*  apos  vp_inrot     (float, float, apos)           Inverse of vp_rot       */
/*  xpos  vp_xrot      (float, float, xpos)           Rotate point            */
/*  xpos  vp_inxrot    (float, float, xpos)           Inverse of vp_xrot      */
/*                                                                            */
/******************************************************************************/

#include <stdio.h>
#include <math.h>
#include "vp_biomag.h" // Riccardo Navarra (test)


/*****************************************************************/
/*  Convert from cartesian coordinates to spherical coordinates  */
/*****************************************************************/
vp_vector vp_car2sph(vp_vector a)
{
   vp_vector b;
   b.comp[0] = (float)sqrt(a.comp[0]*a.comp[0] + a.comp[1]*a.comp[1] + a.comp[2]*a.comp[2]);
   b.comp[1] = 0.;
   b.comp[2] = 0.;
   if (b.comp[0] > 0)
   {
     if ( a.comp[1] != 0. )
     {
       b.comp[2] = (float)atan2(a.comp[1], a.comp[0]);
     }
     else
     {
       b.comp[2] = 0.;
     }
     b.comp[1] = (float)acos(a.comp[2]/b.comp[0]);
   }
   return(b);
}



/*****************************************************************/
/*  Convert from spherical coordinates to cartesian coordinates  */
/*****************************************************************/
vp_vector vp_sph2car(vp_vector a)
{
   vp_vector b;
   b.comp[0] = (float)(a.comp[0] * sin(a.comp[1]) * cos(a.comp[2]));
   b.comp[1] = (float)(a.comp[0] * sin(a.comp[1]) * sin(a.comp[2]));
   b.comp[2] = (float)(a.comp[0] * cos(a.comp[1]));
   return(b);
}



/**********************************************************************************************/
/*  Find coordinates of a vector in S from coordinates in Sp and transformation from S to Sp  */
/**********************************************************************************************/
vp_vector vp_Sp2S(vp_vector in, float dx, float dy, float dz, float th, float fi, float psi)
{
   vp_vector  out;
   double     sinfi, cosfi, sinth, costh, sinpsi, cospsi;

   sinfi  = sin((double)fi);
   cosfi  = cos((double)fi);
   sinth  = sin((double)th);
   costh  = cos((double)th);
   sinpsi = sin((double)psi);
   cospsi = cos((double)psi);

   out.comp[0] = (float)(  ( cospsi*costh*cosfi - sinpsi*sinfi) * in.comp[0]
                         + (-sinpsi*costh*cosfi - cospsi*sinfi) * in.comp[1]
                         + ( sinth*cosfi)                       * in.comp[2]
                         + (double)dx  );

   out.comp[1] = (float)(  ( cospsi*costh*sinfi + sinpsi*cosfi) * in.comp[0]
                         + (-sinpsi*costh*sinfi + cospsi*cosfi) * in.comp[1]
                         + ( sinth*sinfi)                       * in.comp[2]
                         + (double)dy  );

   out.comp[2] = (float)(  (-cospsi*sinth)                      * in.comp[0]
                         + ( sinpsi*sinth)                      * in.comp[1]
                         + ( costh)                             * in.comp[2]
                         + (double)dz  );
   
   return(out);
}



/**********************************************************************************************/
/*  Find coordinates of a vector in Sp from coordinates in S and transformation from S to Sp  */
/**********************************************************************************************/
vp_vector vp_S2Sp(vp_vector in, float dx, float dy, float dz, float th, float fi, float psi)
{
   vp_vector  out;
   double     sinfi, cosfi, sinth, costh, sinpsi, cospsi;

   sinfi  = sin((double)fi);
   cosfi  = cos((double)fi);
   sinth  = sin((double)th);
   costh  = cos((double)th);
   sinpsi = sin((double)psi);
   cospsi = cos((double)psi);

   out.comp[0] = (float)(  ( cospsi*costh*cosfi - sinpsi*sinfi) * (in.comp[0] - dx)
                         + ( cospsi*costh*sinfi + sinpsi*cosfi) * (in.comp[1] - dy)
                         + (-cospsi*sinth)                      * (in.comp[2] - dz) );

   out.comp[1] = (float)(  (-sinpsi*costh*cosfi - cospsi*sinfi) * (in.comp[0] - dx)
                         + (-sinpsi*costh*sinfi + cospsi*cosfi) * (in.comp[1] - dy)
                         + ( sinpsi*sinth)                      * (in.comp[2] - dz) );

   out.comp[2] = (float)(  ( sinth*cosfi)                       * (in.comp[0] - dx)
                         + ( sinth*sinfi)                       * (in.comp[1] - dy)
                         + ( costh)                             * (in.comp[2] - dz) );

   return(out);
}



/************************************************/
/*  Rotate point a(x, y, z) of angles th0, fi0  */
/************************************************/
vp_vector vp_rotate(float th0, float fi0, vp_vector a)
{
   double     sinth0, costh0, sinfi0, cosfi0;
   vp_vector  b;

   sinth0 = sin(th0);
   costh0 = cos(th0);
   sinfi0 = sin(fi0);
   cosfi0 = cos(fi0);

   b.comp[0] = (float)(  (double)a.comp[0] * costh0 * cosfi0
                       - (double)a.comp[1] * sinfi0
                       + (double)a.comp[2] * sinth0 * cosfi0 );

   b.comp[1] = (float)(  (double)a.comp[0] * costh0 * sinfi0
                       + (double)a.comp[1] * cosfi0
                       + (double)a.comp[2] * sinth0 * sinfi0 );

   b.comp[2] = (float)(- (double)a.comp[0] * sinth0
                       + (double)a.comp[2] * costh0 );

   return(b);
}



/************************************************/
/*  Rotate point a(x, y, z) of angles th0, fi0  */
/************************************************/
vp_vector vp_inrotate(float th0, float fi0, vp_vector a)
{
   double     sinth0, costh0, sinfi0, cosfi0;
   vp_vector  b;

   sinth0 = sin(th0);
   costh0 = cos(th0);
   sinfi0 = sin(fi0);
   cosfi0 = cos(fi0);

   b.comp[0] = (float) (  (double)a.comp[0] * costh0 * cosfi0
                        + (double)a.comp[1] * costh0 * sinfi0
                        - (double)a.comp[2] * sinth0 );

   b.comp[1] = (float) (- (double)a.comp[0] * sinfi0
                        + (double)a.comp[1] * cosfi0 );

   b.comp[2] = (float) (  (double)a.comp[0] * sinth0 * cosfi0
                        + (double)a.comp[1] * sinth0 * sinfi0
                        + (double)a.comp[2] * costh0 );

   return(b);
}




/***********************************************************/
/*   Change reference system from POLHEMUS to MEG-ASIMM    */
/***********************************************************/
void vp_polhemus_megasi(int num, position marker[])
{
   int        i;
   float      th0, fi0, dx, dy, dz;
   vp_vector  pos_earr, pos_earl, pos_nasion, pos_vertex, temp;

   for (i=0; i<num; i++)                  /* convert to mm */
   {
      marker[i].r_s.comp[0] *= 10.;
      marker[i].r_s.comp[1] *= 10.;
      marker[i].r_s.comp[2] *= 10.;
   }

   pos_earl =  marker[2].r_s;             /* find left ear position */
   for (i=0; i<num; i++)                  /* move to have left ear in (0,0,0) */
   {
      marker[i].r_s.comp[0] -= pos_earl.comp[0];
      marker[i].r_s.comp[1] -= pos_earl.comp[1];
      marker[i].r_s.comp[2] -= pos_earl.comp[2];
   }

   pos_earr = marker[1].r_s;              /* find new right ear position */
   temp     = vp_car2sph(pos_earr);       
   th0      = temp.comp[1];
   fi0      = temp.comp[2];
   for (i=0; i<num; i++)                  /* rotate to have right ear in (X,0,0) */
   {
      marker[i].r_s = vp_inrotate(th0, fi0, marker[i].r_s);  /* place right ear in (0,0,Z) */
      marker[i].u_s = vp_inrotate(th0, fi0, marker[i].u_s);
	  dx = marker[i].r_s.comp[0];                            /* switch axes to have        */
	  dy = marker[i].r_s.comp[1];                            /* right ear in (X,0,0)       */
	  dz = marker[i].r_s.comp[2];
      marker[i].r_s.comp[0] = dz;
      marker[i].r_s.comp[1] = dx;
      marker[i].r_s.comp[2] = dy;
	  dx = marker[i].u_s.comp[0];                           
	  dy = marker[i].u_s.comp[1];                          
	  dz = marker[i].u_s.comp[2];
      marker[i].u_s.comp[0] = dz;
      marker[i].u_s.comp[1] = dx;
      marker[i].u_s.comp[2] = dy;

   }

   dx = marker[1].r_s.comp[0] / 2;                 /* find origin as midpoint between ears */
   for (i=0; i<num; i++)                           /* move to have right ear in (X,0,0)    */
      marker[i].r_s.comp[0] -= dx;                 /* left ear in (-X,0,0)                 */


   pos_nasion = marker[0].r_s;            /* find new nasion position          */
   if (pos_nasion.comp[1] < 0)            /* if nasion has a negative Y value, */
     for (i=0; i<num; i++)                /* switch y and z sign               */
	 {
		marker[i].r_s.comp[1] = -marker[i].r_s.comp[1];
		marker[i].r_s.comp[2] = -marker[i].r_s.comp[2];
	 }
  
   pos_nasion = marker[0].r_s;            /* find new nasion position          */   
   temp     = vp_car2sph(pos_nasion);     
   th0      = temp.comp[1];
   fi0      = temp.comp[2]; 
   for (i=0; i<num; i++)                  /* rotate to have nasion in (0,0,Z) */
   {
      marker[i].r_s = vp_inrotate(0., fi0, marker[i].r_s);
      marker[i].r_s = vp_inrotate(th0, 0., marker[i].r_s);
      marker[i].u_s = vp_inrotate(0., fi0, marker[i].u_s);
      marker[i].u_s = vp_inrotate(th0, 0., marker[i].u_s);
   }

   for (i=0; i<num; i++)                  /* switch axes to have nasion in (0,Y,0) */
   {
	  dy = marker[i].r_s.comp[1];                           
	  dz = marker[i].r_s.comp[2];
      marker[i].r_s.comp[1] =  dz;
      marker[i].r_s.comp[2] = -dy;
	  dy = marker[i].u_s.comp[1];                           
	  dz = marker[i].u_s.comp[2];
      marker[i].u_s.comp[1] =  dz;
      marker[i].u_s.comp[2] = -dy;
   }

   pos_vertex = marker[3].r_s;            /* find vertex position                           */
   if (pos_vertex.comp[2] < 0)            /* if vertez Z coordinate is negative ...         */
     for (i=0; i<num; i++)                /* invert XZ axes to have vertex with positive Z  */
	 {                                    /* and right ear with positive X                  */
	   marker[i].r_s.comp[0] = -marker[i].r_s.comp[0];                           
	   marker[i].r_s.comp[2] = -marker[i].r_s.comp[2];                           
	 }

/*  Now I am expecting that:  right ear is in ( X, +Y, 0) or ( X, -Y, 0)   */
/*                            left ear  is in (-X, -Y, 0) or (-X, +Y, 0)   */
/*                            nasion    is in ( 0,  Y, 0)                  */
/*  but vertex is at an undetermined position (Z has a positive value)     */

   pos_vertex = marker[3].r_s;            /* find vertex position */
   pos_vertex.comp[1] = 0.;               /* project pos_vertex on XZ plane  */
   temp     = vp_car2sph(pos_vertex);     
   th0      = temp.comp[1];
   for (i=0; i<num; i++)                  /* rotate to have vertex in (0,Y,Z) */
   {
	  marker[i].r_s = vp_inrotate(th0, 0., marker[i].r_s);
      marker[i].u_s = vp_inrotate(th0, 0., marker[i].u_s);
   }

   pos_vertex = marker[3].r_s;            /* find vertex position                           */
   if (pos_vertex.comp[2] < 0)            /* if vertez Z coordinate is negative ...         */
     for (i=0; i<num; i++)                /* invert XZ axes to have vertex with positive Z  */
	 {                                    /* and right ear with positive X                  */
	   marker[i].r_s.comp[0] = -marker[i].r_s.comp[0];
	   marker[i].r_s.comp[2] = -marker[i].r_s.comp[2];
	 }

/* Run previuos section twice since sometimes vertex has a nonzero X component  */
   pos_vertex = marker[3].r_s;            /* find vertex position */
   pos_vertex.comp[1] = 0.;               /* project pos_vertex on XZ plane  */
   temp     = vp_car2sph(pos_vertex);     
   th0      = temp.comp[1];
   for (i=0; i<num; i++)                  /* rotate to have vertex in (0,Y,Z) */
   {   
	  marker[i].r_s = vp_inrotate(th0, 0., marker[i].r_s);
	  marker[i].u_s = vp_inrotate(th0, 0., marker[i].u_s);
   }

   pos_vertex = marker[3].r_s;            /* find vertex position                           */
   if (pos_vertex.comp[2] < 0)            /* if vertez Z coordinate is negative ...         */
     for (i=0; i<num; i++)                /* invert XZ axes to have vertex with positive Z  */
	 {                                    /* and right ear with positive X                  */
	   marker[i].r_s.comp[0] = -marker[i].r_s.comp[0];
	   marker[i].r_s.comp[2] = -marker[i].r_s.comp[2];
	 }


   return;
}


/*************************************************************/
/*  Find the arc of an ellipse with axes A, B with angle TH  */
/*************************************************************/
float vp_arc(float a, float b, float thm)
{
   float  dth, th, rad, arc;

   dth  = (float)0.01;
   th   = 0.;
   arc  = 0.;
   while(th<thm)
   {
      rad = (float)((cos(th)/a)*(cos(th)/a) + (sin(th)/b)*(sin(th)/b));
      rad = (float)sqrt(1./rad);
      th  += dth;
      arc += rad*dth;
   }
   return(arc);
}


/*************************************************************/
/*  Find the angle ANGL of an ellipse arc ARC with axes A, B */
/*************************************************************/
float vp_angle(float a, float b, float arc)
{
   float  dth, dd, rad, angle;

   dth    = (float)0.01;
   angle  = 0.;
   dd     = 0.;
   while(dd<arc)
   {
      rad   = (float)((cos(angle)/a)*(cos(angle)/a) + (sin(angle)/b)*(sin(angle)/b));
      rad   = (float)sqrt(1./rad);
      angle += dth;
      dd    += rad*dth;
   }
   return(angle);
}



/*********************************************/
/*    Old routines. Do not use in new code   */
/*********************************************/

/*************************************************/
/*   Change reference system from NMR to MEG     */
/*************************************************/
void vp_nmr_meg(int n_data, float z_nasion, position marker[], vp_vector data[])
{
   int        i;
   float      sinth0, costh0, th0, fi0, tp;
   float      x_right, x_vertex, x_nasion, z_vertex, x_left, x_shift;
   float      dx_vertex, dx_nasion;
   vp_vector  temp;

   temp = vp_car2sph(marker[3].r_s);             /*  Find th coordinate for vertex  */
   th0  = temp.comp[1];
   if (marker[3].r_s.comp[1] < 0.)               /*  If vertex has negative Y invert rotation angle */
      th0 = -th0;
   sinth0 = (float)sin(th0);
   costh0 = (float)cos(th0);

   for (i=0; i<n_data; i++)                      /*  Rotate data  */
   {
      tp = data[i].comp[1];
      data[i].comp[1] = data[i].comp[1]*costh0 - data[i].comp[2]*sinth0;
      data[i].comp[2] = tp*sinth0 + data[i].comp[2]*costh0;
   }

                                                 /*  Find Z coordinate for nasion  */
   tp = (float)(marker[0].r_s.comp[1]*sinth0 + marker[0].r_s.comp[2]*costh0 - (z_nasion + 20.));

   for (i=0; i<n_data; i++)                      /*  Shift data  */
      data[i].comp[2] -= tp;

/*   Check for possible errors in nasion coil positioning by looking that    */
/*   X(left_ear), X(right_ear), X(vertex) are in a nice proportion.          */
/*   Maximum shift allowed for left/right_ear = 2 mm                         */

   x_right  = marker[1].r_s.comp[0];
   x_vertex = marker[3].r_s.comp[0];
   x_left   = marker[2].r_s.comp[0];
   x_nasion = marker[0].r_s.comp[0];

   x_shift = (float)((x_right + x_left) / 2.);    /*  this is the shift to have ears equally spaced  */

   dx_vertex = x_vertex-x_shift;
   dx_nasion = x_nasion-x_shift;
   if ( (fabs(dx_vertex) > 2.) || (fabs(dx_nasion) > 2.) )
   {
      if ( ((dx_vertex) > 0.) && ((dx_nasion) > 0.) )
         x_shift = x_shift + 1;
      if ( ((dx_vertex) < 0.) && ((dx_nasion) < 0.) )
         x_shift = x_shift - 1;
      if ( ((dx_vertex) > 0.) && ((dx_nasion) < 0.) )
         x_shift = x_shift - 1;
      if ( ((dx_vertex) < 0.) && ((dx_nasion) > 0.) )
         x_shift = x_shift + 1;
   }
   else
      x_shift = (float)((x_vertex + x_shift) / 2.);

   for (i=0; i<n_data; i++)                  /*  Shift data  */
      data[i].comp[0] -= x_shift;


/*  Rotate on Y axis in order to have Vertex at -2<x<2  */

   x_vertex = (marker[3].r_s.comp[0] - x_shift);
   z_vertex = (marker[3].r_s.comp[2] - tp);

   th0 = 0.;
   if (x_vertex < -2.)
   {
      th0 = (float)((-x_vertex-3.) / z_vertex);
      fi0 = 0.0;
   }
   if (x_vertex > 2.)
   {
      th0 = (float)((x_vertex-3.) / z_vertex);
      fi0 = (float)PI;
   }

/*  Check that z displacement of the ears is less than 2 mm  */
   x_right = (marker[1].r_s.comp[0] - x_shift);
   if (th0 > (2./x_right))
      th0 = (float)(2. / x_right);

/*  Check that left-right ear shift is less than 2 mm  */
   x_left  = (marker[2].r_s.comp[0] - x_shift);
   x_right = (marker[1].r_s.comp[0] - x_shift);
   if ( ((x_right+x_left) > 1.0)  && (fi0 == PI) )
      th0 = (float)(th0 / 2.);
   if ( ((x_right+x_left) < -1.0) && (fi0 == 0.) )
      th0 = (float)(th0 / 2.);

   if (th0 > 0.001)
      for (i=0; i<n_data; i++)                      /*  Rotate data  */
      {
         data[i] = vp_rotate  (0. , fi0, data[i]);
         data[i] = vp_rotate  (th0, 0. , data[i]);
         data[i] = vp_inrotate(0. , fi0, data[i]);
      }

   return;
}

/***************************************************/
/*   Change reference system from KHEOPS to NMR    */
/***************************************************/
void vp_kheops_nmr(int num, float z_nasion, position marker[])
{
   int        i;
   float      th0, fi0, dth;
   vp_vector  pos_earr, pos_earl, pos_nasion, temp;

   for (i=0; i<num; i++)                  /* convert to mm */
   {
      marker[i].r_s.comp[0] *= 10.;
      marker[i].r_s.comp[1] *= 10.;
      marker[i].r_s.comp[2] *= 10.;
   }

   pos_earr =  marker[1].r_s;             /* find right ear position */
   for (i=0; i<num; i++)                  /* move to have right ear in (0,0,0) */
   {
      marker[i].r_s.comp[0] -= pos_earr.comp[0];
      marker[i].r_s.comp[1] -= pos_earr.comp[1];
      marker[i].r_s.comp[2] -= pos_earr.comp[2];
   }

   pos_earl = marker[2].r_s;              /* find new left ear position */
   temp     = vp_car2sph(pos_earl);       /* rotate to have left ear in (-X,0,0) */
   th0      = temp.comp[1];
   fi0      = temp.comp[2];
   for (i=0; i<num; i++)
   {
      marker[i].r_s = vp_inrotate(th0, fi0, marker[i].r_s);
      marker[i].r_s = vp_rotate((float)(PI/2.), (float)PI, marker[i].r_s);
   }

/*  Unfortunately sometimes left ear is at (X,0,0) and right ear is (-X,0,0). */
/*  Obviously the previous section is wrong, but is easier to check if this   */
/*  the case and if so, rotate again by PI along the Z axis.                  */
/*  (it may be a bug due to the approximated value of PI).                    */

   if (marker[1].r_s.comp[0] < marker[2].r_s.comp[0])
      for (i=0; i<num; i++)
         marker[i].r_s = vp_rotate(0., (float)PI, marker[i].r_s);

   pos_nasion = marker[0].r_s;            /* find new nasion position */
   for (i=0; i<num; i++)                  /* move to have nasion in (0,Y,Z) */
      marker[i].r_s.comp[0] -= pos_nasion.comp[0];

   pos_nasion = marker[0].r_s;            /* find new nasion position */
   if (pos_nasion.comp[1] < 0)            /* if head is upside down rotate 180 degrees  */
     for (i=0; i<num; i++)
     {
        marker[i].r_s.comp[1] *= (-1.);
        marker[i].r_s.comp[2] *= (-1.);
     }

   if (z_nasion == 0.)  z_nasion += (float)0.2;
   pos_nasion = marker[0].r_s;            /* find new nasion position                    */
   temp       = vp_car2sph(pos_nasion);   /* rotate to have nasion in (0,Y,z_nasion+20)  */
   th0        = temp.comp[1];
   fi0        = temp.comp[2];
   dth        = ((float)(z_nasion + 20.) / temp.comp[0]);
   for (i=0; i<num; i++)
   {
      marker[i].r_s = vp_inrotate(th0, fi0, marker[i].r_s);
      marker[i].r_s = vp_rotate((float)((PI/2.-dth)), (float)(PI/2.), marker[i].r_s);
   }

   return;
}



/*************************************************/
/*   Change reference system from NMR to DATI    */
/*************************************************/
void vp_nmr_dati(int n_data, ch_position marker[], vp_vector data[])
{
   int        i;
   float      sinth0, costh0, th0, tp;
   float      x_right, x_vertex, x_left, x_shift;
   vp_vector  temp;

   temp = vp_car2sph(marker[3].r_s);             /*  Find th coordinate for vertex  */
   th0  = temp.comp[1];
   if (marker[3].r_s.comp[1] < 0.)               /*  If vertex has negative Y invert rotation angle */
      th0 = -th0;
   sinth0 = (float)sin(th0);
   costh0 = (float)cos(th0);

   for (i=0; i<n_data; i++)                      /*  Rotate data  */
   {
      tp = data[i].comp[1];
      data[i].comp[1] = data[i].comp[1]*costh0 - data[i].comp[2]*sinth0;
      data[i].comp[2] = tp*sinth0 + data[i].comp[2]*costh0;
   }

                                                 /*  Find Z coordinate for nasion  */
   tp = (float)(marker[0].r_s.comp[1]*sinth0 + marker[0].r_s.comp[2]*costh0 - 20.);

   for (i=0; i<n_data; i++)                      /*  Shift data  */
      data[i].comp[2] -= tp;

/*   Check for possible errors in nasion coil positioning by looking that    */
/*   X(left_ear), X(right_ear), X(vertex) are in a nice proportion.          */
/*   Maximun shift allowed for left/right_ear = 2 mm                         */

   x_right  = marker[1].r_s.comp[0];
   x_vertex = marker[3].r_s.comp[0];
   x_left   = marker[2].r_s.comp[0];

   x_shift = (float)((x_right + x_left) / 2.);   /*  this is the shift to have ears equally spaced  */

   if ( fabs(x_vertex-x_shift) > 2.)
   {
      if ((x_vertex-x_shift) > 0.)
         x_shift = x_shift + 1;
      if ((x_vertex-x_shift) < 0.)
         x_shift = x_shift - 1;
   }
   else
      x_shift = (float)((x_vertex + x_shift) / 2.);


   for (i=0; i<n_data; i++)                  /*  Shift data  */
      data[i].comp[0] -= x_shift;

   return;
}



/*****************************************************************/
/*  Convert from cartesian coordinates to spherical coordinates  */
/*****************************************************************/
apos vp_car_sph(xpos a)
{
   apos b;
   b.fi = 0;
   b.th = 0;
   b.rd = (float)sqrt(a.x*a.x + a.y*a.y + a.z*a.z);
   if (b.rd > 0)
   {
     if ( a.y != 0. )
     {
       b.fi = (float)atan2(a.y, a.x);
     }
     else
     {
       b.fi = 0.;
     }
     b.th = (float)acos(a.z/b.rd);
   }
   return(b);
}


/*****************************************************************/
/*  Convert from spherical coordinates to cartesian coordinates  */
/*****************************************************************/
xpos vp_sph_car(apos a)
{
   xpos b;
   b.x = (float)(a.rd * sin(a.th) * cos(a.fi));
   b.y = (float)(a.rd * sin(a.th) * sin(a.fi));
   b.z = (float)(a.rd * cos(a.th));
   return(b);
}

/************************************************/
/*  Rotate point a(x, y, z) of angles th0, fi0  */
/************************************************/
xpos vp_xrot(float th0, float fi0, xpos a)
{
   double sinth0, costh0, sinfi0, cosfi0;
   xpos  b;

   sinth0 = sin(th0);
   costh0 = cos(th0);
   sinfi0 = sin(fi0);
   cosfi0 = cos(fi0);

   b.x = (float)(  a.x * costh0 * cosfi0
                 - a.y * sinfi0
                 + a.z * sinth0 * cosfi0 );

   b.y = (float)(  a.x * costh0 * sinfi0
                 + a.y * cosfi0
                 + a.z * sinth0 * sinfi0 );

   b.z = (float)(- a.x * sinth0
                 + a.z * costh0 );

   return(b);
}


xpos vp_inxrot(float th0, float fi0, xpos a)
{
   double sinth0, costh0, sinfi0, cosfi0;
   xpos  b;

   sinth0 = sin(th0);
   costh0 = cos(th0);
   sinfi0 = sin(fi0);
   cosfi0 = cos(fi0);

   b.x = (float)(  a.x * costh0 * cosfi0
                 + a.y * costh0 * sinfi0
                 - a.z * sinth0 );

   b.y = (float)(- a.x * sinfi0
                 + a.y * cosfi0 );

   b.z = (float)(  a.x * sinth0 * cosfi0
                 + a.y * sinth0 * sinfi0
                 + a.z * costh0 );

   return(b);
}


/*************************************************/
/*  Rotate point a(th,fi,rd) of angles th0, fi0  */
/*************************************************/
apos vp_rot(float th0, float fi0, apos a)
{
   double  sinth0, costh0, sinth, costh, sinfi0, cosfi0, sinfi, cosfi;
   float   x, y, z;
   apos    b;

   sinth0 = sin(th0);
   costh0 = cos(th0);
   sinth  = sin(a.th);
   costh  = cos(a.th);
   sinfi0 = sin(fi0);
   cosfi0 = cos(fi0);
   sinfi  = sin(a.fi);
   cosfi  = cos(a.fi);

   x = (float)(  sinth * cosfi * costh0 * cosfi0
               - sinth * sinfi * sinfi0
               + costh         * sinth0 * cosfi0  );

   y = (float)(  sinth * cosfi * costh0 * sinfi0
               + sinth * sinfi * cosfi0
               + costh         * sinth0 * sinfi0  );

   z = (float)(- sinth * cosfi * sinth0
               + costh         * costh0  );

   if (y==0 && x==0)
      b.fi = 0.;
   else
      b.fi = (float)atan2( y, x);
   b.th = (float)acos( z / a.rd );
   b.rd = a.rd;
   return(b);
}


apos vp_inrot(float th0, float fi0, apos a)
{
   double sinth0, costh0, sinth, costh, sinfi0, cosfi0, sinfi, cosfi;
   float x, y, z;
   apos  b;

   sinth0 = sin(th0);
   costh0 = cos(th0);
   sinth  = sin(a.th);
   costh  = cos(a.th);
   sinfi0 = sin(fi0);
   cosfi0 = cos(fi0);
   sinfi  = sin(a.fi);
   cosfi  = cos(a.fi);

   x = (float)(  sinth * cosfi * costh0 * cosfi0
               + sinth * sinfi * costh0 * sinfi0
               - costh         * sinth0  );

   y = (float)(- sinth * cosfi * sinfi0
               + sinth * sinfi * cosfi0  );

   z = (float)(  sinth * cosfi * sinth0 * cosfi0
               + sinth * sinfi * sinth0 * sinfi0
               + costh         * costh0  );

   b.fi = (float)atan2( y, x);
   b.th = (float)acos( z / a.rd);
   b.rd = a.rd;
   return(b);
}