<GameFile>
  <PropertyGroup Name="g_mjBloody_ani_pair" Type="Layer" ID="a401503c-327b-4fe2-bf41-b3d7ddf4a6d4" Version="2.3.3.0" />
  <Content ctype="GameProjectContent">
    <Content>
      <Animation Duration="60" Speed="1.0000" ActivedAnimationName="animation0">
        <Timeline ActionTag="2043668290" Property="Position">
          <PointFrame FrameIndex="0" X="286.1790" Y="94.0719">
            <EasingData Type="0" />
          </PointFrame>
          <PointFrame FrameIndex="30" X="287.1790" Y="94.0719">
            <EasingData Type="0" />
          </PointFrame>
          <PointFrame FrameIndex="60" X="287.1800" Y="94.0719">
            <EasingData Type="0" />
          </PointFrame>
        </Timeline>
        <Timeline ActionTag="2043668290" Property="Scale">
          <ScaleFrame FrameIndex="0" X="1.0000" Y="1.0000">
            <EasingData Type="0" />
          </ScaleFrame>
          <ScaleFrame FrameIndex="30" X="1.0000" Y="1.0000">
            <EasingData Type="0" />
          </ScaleFrame>
          <ScaleFrame FrameIndex="60" X="1.0000" Y="1.0000">
            <EasingData Type="0" />
          </ScaleFrame>
        </Timeline>
        <Timeline ActionTag="2043668290" Property="RotationSkew">
          <ScaleFrame FrameIndex="0" X="0.0000" Y="0.0000">
            <EasingData Type="0" />
          </ScaleFrame>
          <ScaleFrame FrameIndex="30" X="0.0000" Y="0.0000">
            <EasingData Type="0" />
          </ScaleFrame>
          <ScaleFrame FrameIndex="60" X="0.0000" Y="0.0000">
            <EasingData Type="0" />
          </ScaleFrame>
        </Timeline>
        <Timeline ActionTag="2043668290" Property="FileData">
          <TextureFrame FrameIndex="0" Tween="False">
            <TextureFile Type="Normal" Path="g/mjBloody/ani/prepare_tip_quick_dot1.png" Plist="" />
          </TextureFrame>
          <TextureFrame FrameIndex="30" Tween="False">
            <TextureFile Type="Normal" Path="g/mjBloody/ani/prepare_tip_quick_dot1.png" Plist="" />
          </TextureFrame>
          <TextureFrame FrameIndex="60" Tween="False">
            <TextureFile Type="Normal" Path="g/mjBloody/ani/prepare_tip_quick_dot2.png" Plist="" />
          </TextureFrame>
        </Timeline>
        <Timeline ActionTag="2043668290" Property="BlendFunc">
          <BlendFuncFrame FrameIndex="0" Tween="False" Src="770" Dst="771" />
          <BlendFuncFrame FrameIndex="30" Tween="False" Src="770" Dst="771" />
          <BlendFuncFrame FrameIndex="60" Tween="False" Src="770" Dst="771" />
        </Timeline>
        <Timeline ActionTag="2043668290" Property="VisibleForFrame">
          <BoolFrame FrameIndex="0" Tween="False" Value="False" />
          <BoolFrame FrameIndex="30" Tween="False" Value="True" />
        </Timeline>
      </Animation>
      <AnimationList>
        <AnimationInfo Name="animation0" StartIndex="0" EndIndex="90">
          <RenderColor A="150" R="105" G="105" B="105" />
        </AnimationInfo>
      </AnimationList>
      <ObjectData Name="Layer" Tag="120" ctype="GameLayerObjectData">
        <Size X="400.0000" Y="200.0000" />
        <Children>
          <AbstractNodeData Name="_img1" ActionTag="1235645929" Tag="122" IconVisible="False" LeftMargin="42.9478" RightMargin="119.0522" TopMargin="85.1111" BottomMargin="89.8889" ctype="SpriteObjectData">
            <Size X="238.0000" Y="25.0000" />
            <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
            <Position X="161.9478" Y="102.3889" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition X="0.4049" Y="0.5119" />
            <PreSize X="0.5950" Y="0.1250" />
            <FileData Type="Normal" Path="g/mjBloody/ani/prepare_tip_quick_playing.png" Plist="" />
            <BlendFunc Src="770" Dst="771" />
          </AbstractNodeData>
          <AbstractNodeData Name="_img2" ActionTag="2043668290" Tag="123" IconVisible="False" LeftMargin="287.1790" RightMargin="105.8210" TopMargin="103.4281" BottomMargin="91.5719" ctype="SpriteObjectData">
            <Size X="7.0000" Y="5.0000" />
            <AnchorPoint ScaleY="0.5000" />
            <Position X="287.1790" Y="94.0719" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition X="0.7179" Y="0.4704" />
            <PreSize X="0.0175" Y="0.0250" />
            <FileData Type="Normal" Path="g/mjBloody/ani/prepare_tip_quick_dot1.png" Plist="" />
            <BlendFunc Src="770" Dst="771" />
          </AbstractNodeData>
        </Children>
      </ObjectData>
    </Content>
  </Content>
</GameFile>