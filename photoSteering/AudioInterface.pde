import beads.*;

public class AudioInterface
{
  AudioContext ac;
  
  public AudioInterface()
  {
    setupAudio();
  }
  
  void setupAudio()
  {
    ac = new AudioContext();
    /*
     * This is a copy of Lesson 3 with some mouse control.
     */
     //this time we use the Glide object because it smooths the mouse input.
    carrierFreq = new Glide(ac, 500);
    modFreqRatio = new Glide(ac, 1);
    Function modFreq = new Function(carrierFreq, modFreqRatio) {
      public float calculate() {
        return x[0] * x[1];
      }
    };
    WavePlayer freqModulator = new WavePlayer(ac, modFreq, Buffer.SINE);
    Function carrierMod = new Function(freqModulator, carrierFreq) {
      public float calculate() {
        return x[0] * 400.0 + x[1];    
      }
    };
    WavePlayer wp = new WavePlayer(ac, carrierMod, Buffer.SINE);
    Gain g = new Gain(ac, 1, 0.1);
    g.addInput(wp);
    ac.out.addInput(g);
    ac.start(); 
  }
  
  public void makeSound(float inputX, float inputY){
    //mouse listening code here
    carrierFreq.setValue((float)inputX / width * 1000 + 50);
    modFreqRatio.setValue((1 - (float)inputY / height) * 10 + 0.1);
  }
}
