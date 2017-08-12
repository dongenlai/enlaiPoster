<GameFile>
  <PropertyGroup Name="g_mjBloody_ani_dq" Type="Layer" ID="ebb9b4ea-4a12-4c14-b2f2-10aec1e1ca1a" Version="2.3.3.0" />
  <Content ctype="GameProjectContent">
    <Content>
      <Animation Duration="40" Speed="1.0000" ActivedAnimationName="animation0">
        <Timeline ActionTag="216048854" Property="Position">
          <PointFrame FrameIndex="0" X="123.0200" Y="40.3493">
            <EasingData Type="0" />
          </PointFrame>
          <PointFrame FrameIndex="20" X="123.0200" Y="40.3500">
            <EasingData Type="0" />
          </PointFrame>
          <PointFrame FrameIndex="40" X="123.0200" Y="40.3500">
            <EasingData Type="0" />
          </PointFrame>
        </Timeline>
        <Timeline ActionTag="216048854" Property="Scale">
          <ScaleFrame FrameIndex="0" X="1.0000" Y="1.0000">
            <EasingData Type="0" />
          </ScaleFrame>
          <ScaleFrame FrameIndex="20" X="1.0000" Y="1.0000">
            <EasingData Type="0" />
          </ScaleFrame>
          <ScaleFrame FrameIndex="40" X="1.0000" Y="1.0000">
            <EasingData Type="0" />
          </ScaleFrame>
        </Timeline>
        <Timeline ActionTag="216048854" Property="RotationSkew">
          <ScaleFrame FrameIndex="0" X="0.0000" Y="0.0000">
            <EasingData Type="0" />
          </ScaleFrame>
          <ScaleFrame FrameIndex="20" X="0.0000" Y="0.0000">
            <EasingData Type="0" />
          </ScaleFrame>
          <ScaleFrame FrameIndex="40" X="0.0000" Y="0.0000">
            <EasingData Type="0" />
          </ScaleFrame>
        </Timeline>
        <Timeline ActionTag="216048854" Property="FileData">
          <TextureFrame FrameIndex="0" Tween="False">
            <TextureFile Type="Normal" Path="g/mjBloody/ani/PlayerState_point1.png" Plist="" />
          </TextureFrame>
          <TextureFrame FrameIndex="20" Tween="False">
            <TextureFile Type="Normal" Path="g/mjBloody/ani/PlayerState_point2.png" Plist="" />
          </TextureFrame>
          <TextureFrame FrameIndex="40" Tween="False">
            <TextureFile Type="Normal" Path="g/mjBloody/ani/PlayerState_point3.png" Plist="" />
          </TextureFrame>
        </Timeline>
        <Timeline ActionTag="216048854" Property="BlendFunc">
          <BlendFuncFrame FrameIndex="0" Tween="False" Src="770" Dst="771" />
          <BlendFuncFrame FrameIndex="20" Tween="False" Src="770" Dst="771" />
          <BlendFuncFrame FrameIndex="40" Tween="False" Src="770" Dst="771" />
        </Timeline>
      </Animation>
      <AnimationList>
        <AnimationInfo Name="animation0" StartIndex="0" EndIndex="60">
          <RenderColor A="150" R="255" G="0" B="255" />
        </AnimationInfo>
      </AnimationList>
      <ObjectData Name="Layer" Tag="22" ctype="GameLayerObjectData">
        <Size X="180.0000" Y="80.0000" />
        <Children>
          <AbstractNodeData Name="PlayerState_dingqueing_1" ActionTag="-303879107" Tag="24" IconVisible="False" LeftMargin="1.7147" RightMargin="55.2853" TopMargin="19.7137" BottomMargin="16.2863" ctype="SpriteObjectData">
            <Size X="123.0000" Y="44.0000" />
            <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
            <Position X="63.2147" Y="38.2863" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition X="0.3512" Y="0.4786" />
            <PreSize X="0.6833" Y="0.5500" />
            <FileData Type="Normal" Path="g/mjBloody/ani/PlayerState_dingqueing.png" Plist="" />
            <BlendFunc Src="770" Dst="771" />
          </AbstractNodeData>
          <AbstractNodeData Name="img" ActionTag="216048854" Tag="25" IconVisible="False" LeftMargin="123.0200" RightMargin="42.9800" TopMargin="31.6500" BottomMargin="32.3500" ctype="SpriteObjectData">
            <Size X="54.0000" Y="16.0000" />
            <AnchorPoint ScaleY="0.5000" />
            <Position X="123.0200" Y="40.3500" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition X="0.6834" Y="0.5044" />
            <PreSize X="0.3000" Y="0.2000" />
            <FileData Type="Normal" Path="g/mjBloody/ani/PlayerState_point3.png" Plist="" />
            <BlendFunc Src="770" Dst="771" />
          </AbstractNodeData>
        </Children>
      </ObjectData>
    </Content>
  </Content>
</GameFile>