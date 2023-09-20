<system axiom="branch(1)">
  <grammar type="parametric">
    <symbol match="branch($age)">branch($age+1)</symbol>
    <symbol match="leaf()">
      branch(1),
      push(), turn(+45), branch(1), leaf(),
      pop(),  turn(-45), branch(1), leaf()
    </symbol>
    <terminal match="push()" />
    <terminal match="pop()" />
    <terminal match="turn($deg)" />
  </grammar>
</system>