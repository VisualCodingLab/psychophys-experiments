<h1>Contrast Adaptation Experiment</h1>
<h3>Outline</h3>
This experiment tests contrast sensitivity to adaptations at different spatial frequencies. To test this, the user is subjected to periods of defined adaptation, and then shown  gabors with different frequencies, and asked which side they appear. There are 2 experiment files that can be run: measureCSF.m & measureCSFadapt.m. 

<h3>Runnable Experiment Files</h3>
<b>measureCSF.m: </b>
Measures baseline contrast sensitivity (without adaptation)
<br><b>measureCSFadapt.m: </b>
Measures contrast sensitivity with adaptation. Note it is possible to measure baseline with this by settings adaptation durations to 0.

<h3>Other Files</h3>
<b>csf_base.m: </b>Class used to create gabor stimuli, and fixate behaviours from neurostim<br>
<b>fixate_adapt.m: </b>Custom eyeMovement behaviour, used to turn center point red during adaptation<br>
<b>csfPostProcessing.m: </b>Fucntion that takes a cic input or file string pointing to a cic, and runs any relavent analysis<br>

<h3>Experiment Flow</h3>
1. User should ensure they are looking at the center fixation point for the entire experiment <br>
2. User subjected to initial adaptation (2 maximum contrast gabors either side)<br>
3. Trials consist of a gabor displaying left or right for a small amount of time<br>
4. User then presses "A" for left, and "L" for right<br>
5. Top up adaptations may occur before any trial. These are identifiable as they will have 2 maximum contrast gabors either side

<h3>Experiment Behaviour</h3>
- Adaptations and trials won't start unless the user is fixating at the center point<br>
- During adaptation, center point will turn red if not fixating at the center<br>
- During trials, trial will stop and repeated later in a random slot if not fixating at the center (a bloop sound will play)<br>
- Trials will begin straight after adaptation (or with some specified time delay)<br>
- Trials will indicate if a correct selection has been made with a sound

<h3>Parameters (for experimenter)</h3>
<table>
  <tr>
    <th>Parameter</th>
    <th>Definition</th>
    <th>Range</th>
    <th>Location</th>
  </tr>
  <tr>
    <td>Inputs</td>
    <td>The contrasts, frequencies & how many repetitions</td>
    <td>Contrast: [0 1]</td>
    <td>measureCSF.m, measureCSFadapt.m (lines:12-14)</td>
  </tr>
  <tr>
    <td>Adaptation Params</td>
    <td>Initial & cyclic durations, delays & Adaptation frequency</td>
    <td>No range</td>
    <td>measureCSFadapt.m (lines: 20-24)</td>
  </tr>
  <tr>
    <td>Gabor Stimulus On Time</td>
    <td>stimulus_on_time</td>
    <td>>0</td>
    <td>csf_base.m (line: 17)</td>
  </tr>
  <tr>
    <td>Eye Tracker Tolerance</td>
    <td>fix.tolerance, adaptFix.tolerance</td>
    <td>>0</td>
    <td>csf_base.m (lines: 115 (during trial), 133 (during adaptation))</td>
  </tr>
</table>
