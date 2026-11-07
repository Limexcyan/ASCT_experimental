/***********************************/
/*  ViP library  - head utilities  */
/*                                 */
/*  by Vittorio Pizzella           */
/*                                 */
/*  Version 14.0.1                 */
/*                                 */
/*  Last revision:  May 24, 2003   */
/***********************************/

/********************************************************************************/
/*  Library for biomag programs. Head utilities                                 */
/*                                                                              */
/*  void      vp_get_ellipsoid                                                  */
/*            (ch_position marker[], float *a_ell, float *b_ell, float *c_ell)  */
/*  float     rd_given_th_and_fi                                                */
/*            (vp_vector surf_sph[], float final_th, float final_fi)            */
/*  float     distance_given_th_and_fi                                          */
/*            (vp_vector surf_sph[], float final_th, float final_fi)            */
/*  vp_vector point_given_fi_and_distance                                       */
/*            (vp_vector surf_sph[], float final_fi, float final_distance)      */
/*  vp_vector normal_given_point                                                */
/*            (vp_vector surf_sph[], vp_vector point)                           */
/********************************************************************************/

#include <stdio.h>
#include <math.h>
#include <string.h>
// #include "vp_biomag.h" Riccardo Navarra (test)
#include "lc_support.h"

/***************************************************************************/
/*  Find ellipsoid axes in DATI reference system from marker position.     */
/*  If marker position is not available, default ellipsoid (95, 105, 110)  */
/*  is given.                                                              */
/***************************************************************************/

void vp_get_ellipsoid (ch_position marker[], float *a_ell, float *b_ell, float *c_ell)
{
   int           i, ell_default;
   vp_vector     new_marker[4];

/*  Copy marker position to new_marker and check if all markers (nasion, preauricolar points, vertex) */
/*  are well defined.                                                                                 */
   ell_default = 0;
   for (i=0; i<4; i++)
   {
      new_marker[i] = marker[i].r_s;
      if (marker[i].r_s.comp[0] == 0 && marker[i].r_s.comp[1] == 0 && marker[i].r_s.comp[2] == 0)
         ell_default = 1;
   }
/*  If not use default values  */
   if (ell_default == 1)
   {
      *a_ell = 95.;
      *b_ell = 105.;
      *c_ell = 110.;
   }

/*  Otherwise compute axes  */
   if (ell_default == 0)
   {
      vp_nmr_dati(4, marker, new_marker);          /*  Transform to DATI reference system  */
      *a_ell = (new_marker[1].comp[0] - new_marker[2].comp[0]) / (float)2.;
      *b_ell =  new_marker[0].comp[1];
      *c_ell =  new_marker[3].comp[2];
   }

   return;
}


/***********************************************************/
/*  Find radius on the surface of a given point (th, fi)   */
/***********************************************************/

float rd_given_th_and_fi (vp_vector surf_sph[], float final_th, float final_fi)
{
   int     i;

   if (final_fi > 0.5*PI) final_fi -= (float)(2.*PI);
   i = 5;

/*  search for index of a close point on the surface */
   while (surf_sph[i].comp[1] <= (final_th - 0.01) )
      i++;

   while (surf_sph[i].comp[2] > surf_sph[i+1].comp[2] && surf_sph[i].comp[2] >= final_fi)
      i++;

   i--;
   return(surf_sph[i].comp[0]);
}


/*****************************************************************************/
/*  Find the distance on the surface from vertex to a given point (th, fi)   */
/*****************************************************************************/

float distance_given_th_and_fi (vp_vector surf_sph[], float final_th, float final_fi)
{
   int     i, istart;
   float   distance, previous_point[3], point[3], fact;

   if (final_fi > 0.5*PI) final_fi -= (float)(2.*PI);
   distance = 0.;
   previous_point[0] = surf_sph[5].comp[0];
   previous_point[1] = surf_sph[5].comp[1];
   previous_point[2] = surf_sph[5].comp[2];
   point[0] = surf_sph[6].comp[0];
   point[1] = surf_sph[6].comp[1];
   point[2] = surf_sph[6].comp[2];

   i = 6;

/*  execute loop until th value is less then predefined th value */
   while (point[1] < final_th)
   {
      istart = i;
/*  search for the two points on the grid at a fixed th value and fi nearest to final_fi  */
      while ( surf_sph[i].comp[2]>final_fi && (surf_sph[i].comp[2]-surf_sph[i+1].comp[2])>0 )
         i++;

      if ( surf_sph[i].comp[2] > final_fi )   /*  if last point at the fixed th value  */
      {
         fact = (final_fi - surf_sph[istart].comp[2]) / (surf_sph[i].comp[2] - surf_sph[istart].comp[2]);
         point[0] = surf_sph[istart].comp[0] + (surf_sph[i].comp[0] - surf_sph[istart].comp[0]) * fact;
         point[1] = surf_sph[istart].comp[1] + (surf_sph[i].comp[1] - surf_sph[istart].comp[1]) * fact;
      }
      else
      {
         fact = (final_fi - surf_sph[i].comp[2]) / (surf_sph[i-1].comp[2] - surf_sph[i].comp[2]);
         point[0] = surf_sph[i].comp[0] + (surf_sph[i-1].comp[0] - surf_sph[i].comp[0]) * fact;
         point[1] = surf_sph[i].comp[1] + (surf_sph[i-1].comp[1] - surf_sph[i].comp[1]) * fact;
      }

/*  compute distance between two points at successive th values */
      if (point[1]<final_th)
         distance += (previous_point[0] + point[0]) / 2 * (point[1] - previous_point[1]);
      else
      distance += (previous_point[0] + point[0]) / 2 * (final_th - previous_point[1]);
      previous_point[0] = point[0];
      previous_point[1] = point[1];

/*  position index to the first point of next th value */
      while ( (surf_sph[i].comp[2]-surf_sph[i+1].comp[2])>0. )
         i++;
      i++;
   }
   return(distance);
}


/*****************************************************************************/
/*  Find the point on the surface at a given fi and distance from the vertex */
/*****************************************************************************/

vp_vector point_given_fi_and_distance (vp_vector surf_sph[], float final_fi, float final_distance)
{
   int     i, istart;
   float   distance, previous_point[3], point[3], fact;
   vp_vector  final_point;

   if (final_fi > 0.5*PI) final_fi -= (float)(2.*PI);
   distance = 0.;
   previous_point[0] = surf_sph[5].comp[0];
   previous_point[1] = surf_sph[5].comp[1];
   previous_point[2] = surf_sph[5].comp[2];
   i = 6;

/*  execute loop until distance from vertex is less then predefined distance */
   while (distance < final_distance)
   {
      istart = i;
/*  search for the two point on the grid at a fixed th value and fi nearest to final_fi  */
      while ( surf_sph[i].comp[2]>final_fi && (surf_sph[i].comp[2]-surf_sph[i+1].comp[2])>0 )
         i++;

      if ( surf_sph[i].comp[2] > final_fi )   /*  if last point at the fixed th value  */
      {
         fact = (final_fi - surf_sph[istart].comp[2]) / (surf_sph[i].comp[2] - surf_sph[istart].comp[2]);
         point[0] = surf_sph[istart].comp[0] + (surf_sph[i].comp[0] - surf_sph[istart].comp[0]) * fact;
         point[1] = surf_sph[istart].comp[1] + (surf_sph[i].comp[1] - surf_sph[istart].comp[1]) * fact;
      }
      else
      {
         fact = (final_fi - surf_sph[i].comp[2]) / (surf_sph[i-1].comp[2] - surf_sph[i].comp[2]);
         point[0] = surf_sph[i].comp[0] + (surf_sph[i-1].comp[0] - surf_sph[i].comp[0]) * fact;
         point[1] = surf_sph[i].comp[1] + (surf_sph[i-1].comp[1] - surf_sph[i].comp[1]) * fact;
      }

/*  compute distance between to points at successive th values */
      distance += (previous_point[0] + point[0]) / 2 * (point[1] - previous_point[1]);
      previous_point[0] = point[0];
      previous_point[1] = point[1];

/*  position index to the first point of next th value */
      while ( (surf_sph[i].comp[2]-surf_sph[i+1].comp[2])>0 )
         i++;
      i++;
   }

   final_point.comp[0] = (float)(point[0] * sin(point[1]) * cos(final_fi));
   final_point.comp[1] = (float)(point[0] * sin(point[1]) * sin(final_fi));
   final_point.comp[2] = (float)(point[0] * cos(point[1]));

   return(final_point);

}



/*****************************************************/
/*  Find the normal to the surface at a given point  */
/*****************************************************/

vp_vector normal_given_point (vp_vector surf_sph[], vp_vector point)
{
   float      th, fi, rd, amp;
   vp_vector  norm;

   rd = (float)sqrt(point.comp[0]*point.comp[0] + point.comp[1]*point.comp[1]
                  + point.comp[2]*point.comp[2]);
   th = (float)acos(point.comp[2] / rd);
   if (point.comp[0]==0 && point.comp[1]==0)
      fi = 0.;
   else
      fi = (float)atan2(point.comp[1], point.comp[0]);

   rd += 1.;

   norm.comp[0] = (float)(rd * sin(th) * cos(fi));
   norm.comp[1] = (float)(rd * sin(th) * sin(fi));
   norm.comp[2] = (float)(rd * cos(th));

   amp = (float)sqrt(norm.comp[0]*norm.comp[0] + norm.comp[1]*norm.comp[1]
                   + norm.comp[2]*norm.comp[2]);

   norm.comp[0] = norm.comp[0] / amp;
   norm.comp[1] = norm.comp[1] / amp;
   norm.comp[2] = norm.comp[2] / amp;

   return(norm);
}


#if 0
vp_vector normal_given_point (vp_vector surf_sph[], vp_vector point)
{
   int        i, i0, i1, i2, i3, i4;
   vp_vector  d1, d2, d3, d4, d5, d6, n1, n2, n3, n4, n5, n6, norm;
   float      final_th, final_fi, amp;

   vp_vector vp_vect_diff(vp_vector, vp_vector);
   vp_vector vp_vect_vect(vp_vector, vp_vector);


   final_th = acos(point.comp[2] / sqrt(point.comp[0]*point.comp[0]
               + point.comp[1]*point.comp[1] + point.comp[2]*point.comp[2]));
   if (point.comp[0]==0 && point.comp[1]==0)
      final_fi = 0.;
   else
      final_fi = atan2(point.comp[1], point.comp[0]);
   if (final_fi > (0.5*PI)) final_fi -= 2. * PI;

/*  Find closest point on surface  */

   i = 0;
   while (surf_sph[i].comp[1] <= (final_th - 0.01) )
      i++;
   while (surf_sph[i].comp[2] > surf_sph[i+1].comp[2] && surf_sph[i].comp[2] >= final_fi)
      i++;
   i--;

   if (i <= 6)                                      /*  If point very close to vertex            */
                                                    /*  (or first circle) take vertex direction  */
   {
      d1 = vp_vect_diff(surf_sph[1], surf_sph[0]);
      d2 = vp_vect_diff(surf_sph[2], surf_sph[0]);
      d3 = vp_vect_diff(surf_sph[3], surf_sph[0]);
      d4 = vp_vect_diff(surf_sph[4], surf_sph[0]);
      d5 = vp_vect_diff(surf_sph[5], surf_sph[0]);
      d6 = vp_vect_diff(surf_sph[6], surf_sph[0]);
      n1 = vp_vect_vect(d2, d1);
      n2 = vp_vect_vect(d3, d2);
      n3 = vp_vect_vect(d4, d3);
      n4 = vp_vect_vect(d5, d4);
      n5 = vp_vect_vect(d6, d5);
      n6 = vp_vect_vect(d1, d6);
   }
   else
   {
      i0 = i;                  /* point itself */
      i1 = i-1;                /* point with greater fi  */
      i3 = i+1;                /* point with smaller fi  */

      while (surf_sph[i].comp[1] == surf_sph[i0].comp[1])   /*  point with greater th  */
         i++;
      while (surf_sph[i].comp[2] >= final_fi)
         i++;
      i2 = i-1;

      i = i0;
      while (surf_sph[i].comp[1] == surf_sph[i0].comp[1])   /*  point with smaller th  */
         i--;
      while (surf_sph[i].comp[2] <= final_fi)
         i--;
      i4 = i+1;

/*  Find vectors connecting point to neighboors  */

      d1 = vp_vect_diff(surf_sph[i1], surf_sph[i0]);
      d2 = vp_vect_diff(surf_sph[i2], surf_sph[i0]);
      d3 = vp_vect_diff(surf_sph[i3], surf_sph[i0]);
      d4 = vp_vect_diff(surf_sph[i4], surf_sph[i0]);

      n1 = vp_vect_vect(d1, d2);
      n2 = vp_vect_vect(d2, d3);
      n3 = vp_vect_vect(d3, d4);
      n4 = vp_vect_vect(d4, d1);
      n5.comp[0] = 0.;   n5.comp[1] = 0.;   n5.comp[2] = 0.;
      n6.comp[0] = 0.;   n6.comp[1] = 0.;   n6.comp[2] = 0.;
   }

   norm.comp[0] = n1.comp[0] + n2.comp[0] + n3.comp[0] + n4.comp[0] + n5.comp[0] + n6.comp[0];
   norm.comp[1] = n1.comp[1] + n2.comp[1] + n3.comp[1] + n4.comp[1] + n5.comp[1] + n6.comp[1];
   norm.comp[2] = n1.comp[2] + n2.comp[2] + n3.comp[2] + n4.comp[2] + n5.comp[2] + n6.comp[2];

   amp = sqrt(norm.comp[0]*norm.comp[0] + norm.comp[1]*norm.comp[1]
           + norm.comp[2]*norm.comp[2]);

   norm.comp[0] = -norm.comp[0] / amp;
   norm.comp[1] = -norm.comp[1] / amp;
   norm.comp[2] = -norm.comp[2] / amp;

   return(norm);
}

#endif


vp_vector vp_vect_diff(vp_vector A, vp_vector B)
{
   vp_vector     a, b, c;

   a.comp[0] = (float)(A.comp[0] * sin(A.comp[1]) * cos(A.comp[2]));
   a.comp[1] = (float)(A.comp[0] * sin(A.comp[1]) * sin(A.comp[2]));
   a.comp[2] = (float)(A.comp[0] * cos(A.comp[1]));
   b.comp[0] = (float)(B.comp[0] * sin(B.comp[1]) * cos(B.comp[2]));
   b.comp[1] = (float)(B.comp[0] * sin(B.comp[1]) * sin(B.comp[2]));
   b.comp[2] = (float)(B.comp[0] * cos(B.comp[1]));

   c.comp[0]     = a.comp[0] - b.comp[0];
   c.comp[1]     = a.comp[1] - b.comp[1];
   c.comp[2]     = a.comp[2] - b.comp[2];

   return c;
}


vp_vector vp_vect_vect(vp_vector A, vp_vector B)
{
   vp_vector     C;

   C.comp[0]     = A.comp[1] * B.comp[2] - A.comp[2] * B.comp[1];
   C.comp[1]     = A.comp[2] * B.comp[0] - A.comp[0] * B.comp[2];
   C.comp[2]     = A.comp[0] * B.comp[1] - A.comp[1] * B.comp[0];

   return C;
}
