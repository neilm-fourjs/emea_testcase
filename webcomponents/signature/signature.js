// This function is called by the Genero Client Container
// so the web component can initialize itself and initialize
// the gICAPI handlers
onICHostReady = function(version) {
   if ( version != 1.0 ) {
      alert('Invalid API version');
      return;
   }

   // Initialize the focus handler called by the Genero Client
   // Container when the DVM set/remove the focus to/from the
   // component
   gICAPI.onFocus = function(polarity) {
      /* looks bad on IOS, we need to add a possibility to know the client
      if ( polarity ) {
         document.body.style.border = '1px solid blue';
      } else {
         document.body.style.border = '1px solid grey';
      }
      */
   }
            
   gICAPI.onData = function(data) {
     signaturePath = data;
     p.setAttribute('d', data);
   }
   

   gICAPI.onProperty = function(property) {
   }

}

function checkSvg() {
   r = document.getElementById('r');
   p = document.getElementById('p');
   signaturePath = '',
   isDown = false;
   r.addEventListener('mousedown', down, false);
   r.addEventListener('mousemove', move, false);
   r.addEventListener('mouseup', up, false);
   r.addEventListener('touchstart', down, false);
   r.addEventListener('touchmove', move, false);
   r.addEventListener('touchend', up, false);
   r.addEventListener('mouseout', up, false);
}

function isTouchEvent(e) {
   return e.type.match(/^touch/);
}

function getCoords(e) {
  if (isTouchEvent(e)) {
     return e.targetTouches[0].clientX + ',' + e.targetTouches[0].clientY;
  }
  return e.clientX + ',' + e.clientY;
}

function down(e) {
  // Make sure has the 4gl focus if user clicks inside
  // Seems to cause the GDC to crash
  gICAPI.SetFocus();
      
  signaturePath += 'M' + getCoords(e) + ' ';
  p.setAttribute('d', signaturePath);
  isDown = true;
      
  if (isTouchEvent(e)) e.preventDefault();
  gICAPI.SetData(signaturePath);
}

function move(e) {
  if (isDown) {
    signaturePath += 'L' + getCoords(e) + ' ';
    p.setAttribute('d', signaturePath);
  }

  if (isTouchEvent(e)) e.preventDefault();
  gICAPI.SetData(signaturePath);
}

function up(e) {
  isDown = false; 

  if (isTouchEvent(e)) e.preventDefault();

  // update the data when end of movement 
  gICAPI.SetData(signaturePath);
}

function clearSignature() {
   signaturePath = '';
   p.setAttribute('d', '');
   gICAPI.SetData(signaturePath);
}
