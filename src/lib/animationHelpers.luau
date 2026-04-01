-- StepAnimations(0) often fails to fully resolve the pose in a WorldModel (partial blend /
-- low effective weight). Real playback uses StepAnimations(dt) with dt > 0. For scrubbing we
-- freeze the track, step with a nominal frame, then snap TimePosition back if anything drifted.
local Constants = require(script.Parent.Parent.Constants)
local POSE_RESOLVE_DT = Constants.FRAME_DT

local function applyAnimationPoseAtTime(animator: Animator, track: AnimationTrack, timePosition: number)
	track:AdjustSpeed(0)
	track.TimePosition = timePosition
	animator:StepAnimations(POSE_RESOLVE_DT)
	track.TimePosition = timePosition
end

local function getOrCreateAnimator(instance: Instance): Animator?
	local humanoid = instance:FindFirstChildWhichIsA("Humanoid")
	if humanoid then
		local animator = humanoid:FindFirstChildWhichIsA("Animator")
		if not animator then
			animator = Instance.new("Animator")
			animator.Parent = humanoid
		end
		return animator
	end

	local animController = instance:FindFirstChildWhichIsA("AnimationController")
	if not animController then
		animController = Instance.new("AnimationController")
		animController.Parent = instance
	end
	local animator = animController:FindFirstChildWhichIsA("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = animController
	end
	return animator
end

return {
	applyAnimationPoseAtTime = applyAnimationPoseAtTime,
	getOrCreateAnimator = getOrCreateAnimator,
}
